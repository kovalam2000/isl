"""
CelesTrak TLE fetching and satellite catalog.

Primary source: CelesTrak live TLE fetch (always returns current orbital data).
Fallback: synthetically generated TLEs with today's epoch so the simulation
         always shows physically meaningful orbits even when offline.
"""

import logging
import math
from datetime import datetime, timezone
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Satellite catalog (for UI dropdowns)
# ---------------------------------------------------------------------------
CATALOG = {
    "Space Stations": [
        {"name": "ISS (ZARYA)",    "norad": "25544"},
        {"name": "Tiangong (CSS)", "norad": "48274"},
    ],
    "Starlink (LEO ~550 km)": [
        {"name": "STARLINK-1007",  "norad": "44713"},
        {"name": "STARLINK-1008",  "norad": "44714"},
        {"name": "STARLINK-1015",  "norad": "44721"},
        {"name": "STARLINK-2095",  "norad": "47652"},
        {"name": "STARLINK-3090",  "norad": "52751"},
    ],
    "OneWeb (LEO ~1200 km)": [
        {"name": "ONEWEB-0010",    "norad": "44058"},
        {"name": "ONEWEB-0012",    "norad": "44060"},
        {"name": "ONEWEB-0016",    "norad": "44067"},
        {"name": "ONEWEB-0040",    "norad": "44094"},
    ],
    "Earth Observation": [
        {"name": "TERRA",          "norad": "25994"},
        {"name": "AQUA",           "norad": "27424"},
        {"name": "LANDSAT 8",      "norad": "39084"},
        {"name": "SENTINEL-2A",    "norad": "40697"},
        {"name": "SENTINEL-2B",    "norad": "42063"},
    ],
    "GPS / Navigation (MEO)": [
        {"name": "GPS BIIF-1 (PRN09)", "norad": "40105"},
        {"name": "GPS BIIF-2 (PRN01)", "norad": "41019"},
        {"name": "GLONASS-M 754",      "norad": "43508"},
        {"name": "GALILEO 5 (E18)",    "norad": "40544"},
    ],
    "Geostationary (GEO)": [
        {"name": "GOES-16",        "norad": "41866"},
        {"name": "GOES-18",        "norad": "51850"},
        {"name": "INTELSAT 901",   "norad": "26824"},
        {"name": "ASTRA 1N",       "norad": "38652"},
    ],
}

# ---------------------------------------------------------------------------
# Synthetic TLE generation (offline fallback)
# Generates TLEs with the current epoch so propagation always starts at a
# well-defined, physically meaningful position regardless of when the code runs.
# ---------------------------------------------------------------------------

def _tle_checksum(line: str) -> int:
    """Compute the TLE line checksum (mod-10 weighted digit sum)."""
    total = 0
    for c in line:
        if c.isdigit():
            total += int(c)
        elif c == '-':
            total += 1
    return total % 10


def _n(alt_km: float) -> float:
    """Mean motion in rev/day for a circular orbit at given altitude."""
    mu = 398600.441  # km³/s²
    a = 6378.137 + alt_km
    return math.sqrt(mu / a**3) * 86400.0 / (2.0 * math.pi)


def _make_tle(
    name: str,
    norad: int,
    inc_deg: float,
    raan_deg: float,
    ecc: float,
    argp_deg: float,
    ma_deg: float,
    mean_motion_revday: float,
    bstar: float = 1e-4,
) -> dict:
    """
    Build a valid 3-line TLE set with today's epoch and proper checksums.

    Orbital elements follow the standard Keplerian convention:
      inc_deg            – inclination [deg]
      raan_deg           – RAAN [deg]
      ecc                – eccentricity
      argp_deg           – argument of perigee [deg]
      ma_deg             – mean anomaly at epoch [deg]
      mean_motion_revday – mean motion [rev/day]
      bstar              – B* drag term
    """
    now = datetime.now(timezone.utc)
    yr2  = now.year % 100
    doy  = now.timetuple().tm_yday + (
        now.hour * 3600 + now.minute * 60 + now.second
    ) / 86400.0

    # Encode BSTAR as "±MMMMM-E" (5-digit mantissa, single-digit exponent)
    if bstar == 0.0:
        bstar_str = " 00000-0"
    else:
        exp = int(math.floor(math.log10(abs(bstar)))) + 1
        mantissa_int = int(round(bstar / 10**exp * 1e5))
        sign = "-" if bstar < 0 else " "
        bstar_str = f"{sign}{abs(mantissa_int):05d}-{abs(exp)}"

    norad_str = f"{norad:05d}"

    # Line 1  (68-char body + 1-char checksum = 69 chars total, per TLE standard)
    # Field widths: [1][2][3-7][8][9][10-17][18][19-20][21-32][33][34-43][44][45-52][53][54-61][62][63][64][65-68][69]
    line1_body = (
        f"1 {norad_str}U 00001A   {yr2:02d}{doy:012.8f} "
        f" .00000000  00000-0 {bstar_str} 0  999"
    )
    line1 = line1_body + str(_tle_checksum(line1_body))

    # Eccentricity encoded as 7-digit integer (decimal point assumed at front)
    ecc_str = f"{ecc:.7f}"[2:]   # e.g. "0.0001311" → "0001311"

    # Line 2  (68 chars + checksum)
    line2_body = (
        f"2 {norad_str} {inc_deg:8.4f} {raan_deg:8.4f} {ecc_str} "
        f"{argp_deg:8.4f} {ma_deg:8.4f} {mean_motion_revday:11.8f}00000"
    )
    line2 = line2_body + str(_tle_checksum(line2_body))

    return {
        "name":  name,
        "norad": str(norad),
        "line1": line1,
        "line2": line2,
        "stale": True,   # mark as synthetic / offline fallback
    }


# ---------------------------------------------------------------------------
# Fallback TLE registry — built once at import time with today's epoch
# ---------------------------------------------------------------------------
_FALLBACK_TLES: dict[str, dict] = {}

def _fb(name: str, norad: int, inc: float, raan: float, ecc: float,
        argp: float, ma: float, alt_km: float, bstar: float = 1e-4):
    """Shorthand for registering a fallback TLE."""
    t = _make_tle(name, norad,
                  inc_deg=inc, raan_deg=raan, ecc=ecc,
                  argp_deg=argp, ma_deg=ma,
                  mean_motion_revday=_n(alt_km), bstar=bstar)
    _FALLBACK_TLES[str(norad)] = t

#                   name              norad    inc    raan   ecc       argp   ma      alt_km  bstar
# ─── Space stations ────────────────────────────────────────────────────────────────────────────
# ISS: start at ascending node (MA=0°, RAAN=0°) — guarantees interesting geometry with OneWeb
_fb("ISS (ZARYA)",    25544,  51.64,   0.0, 0.000131,  90.0,   0.0,  410,   1.8e-5)
_fb("Tiangong (CSS)", 48274,  41.47,  60.0, 0.000400,  90.0,  30.0,  390,   5.0e-5)
# ─── Starlink (~550 km, 53°) — similar plane to ISS, different mean anomaly ────────────────────
_fb("STARLINK-1007", 44713,  53.05,   0.0, 0.000120,  90.0,  20.0,  550,   1.1e-4)
_fb("STARLINK-1008", 44714,  53.05,  30.0, 0.000120,  90.0,  45.0,  550,   1.1e-4)
_fb("STARLINK-1015", 44721,  53.05,  60.0, 0.000120,  90.0,  90.0,  550,   1.1e-4)
_fb("STARLINK-2095", 47652,  53.05, 120.0, 0.000120,  90.0, 180.0,  550,   1.1e-4)
_fb("STARLINK-3090", 52751,  53.22, 180.0, 0.000120,  90.0, 270.0,  550,   1.1e-4)
# ─── OneWeb (~1200 km, 87.9°) — start near RAAN=0° to cross ISS ground track early ────────────
_fb("ONEWEB-0010",   44058,  87.92,   0.0, 0.000200,  75.0,  20.0, 1200,   9.8e-5)
_fb("ONEWEB-0012",   44060,  87.90,  30.0, 0.000200,  75.0,  60.0, 1200,   9.5e-5)
_fb("ONEWEB-0016",   44067,  87.90,  60.0, 0.000200,  75.0, 120.0, 1200,   9.5e-5)
_fb("ONEWEB-0040",   44094,  87.90, 120.0, 0.000200,  75.0, 200.0, 1200,   9.5e-5)
# ─── Sun-synchronous EO (~705–786 km, ~98°) ─────────────────────────────────────────────────
_fb("TERRA",         25994,  98.21, 200.0, 0.000100,  90.0, 270.0,  705,   2.8e-5)
_fb("AQUA",          27424,  98.21, 200.0, 0.000110,  90.0, 274.0,  705,   2.8e-5)
_fb("LANDSAT 8",     39084,  98.22, 200.0, 0.000110,  90.0, 260.0,  705,   1.6e-5)
_fb("SENTINEL-2A",   40697,  98.57, 200.0, 0.000100,  90.0, 270.0,  786,   1.6e-5)
_fb("SENTINEL-2B",   42063,  98.57, 200.0, 0.000100,  90.0,  90.0,  786,   1.6e-5)
# ─── GPS / Galileo / GLONASS (MEO) ──────────────────────────────────────────────────────────
_fb("GPS BIIF-1 (PRN09)", 40105, 55.0,  80.0, 0.010,  90.0, 270.0, 20200, 0.0)
_fb("GPS BIIF-2 (PRN01)", 41019, 55.0, 140.0, 0.010,  90.0, 270.0, 20200, 0.0)
_fb("GLONASS-M 754",      43508, 64.8, 100.0, 0.001,  90.0, 270.0, 19100, 0.0)
_fb("GALILEO 5 (E18)",    40544, 56.0, 120.0, 0.0003, 90.0, 270.0, 23200, 0.0)
# ─── Geostationary (GEO) ────────────────────────────────────────────────────────────────────
_fb("GOES-16",      41866, 0.05, 285.0, 0.0005, 0.0, 0.0, 35786, 0.0)
_fb("GOES-18",      51850, 0.03, 223.0, 0.0003, 0.0, 0.0, 35786, 0.0)
_fb("INTELSAT 901", 26824, 0.02,  60.0, 0.0002, 0.0, 0.0, 35786, 0.0)
_fb("ASTRA 1N",     38652, 0.01,  19.2, 0.0001, 0.0, 0.0, 35786, 0.0)

# ---------------------------------------------------------------------------
# CelesTrak endpoints
# ---------------------------------------------------------------------------
_TLE_BY_NORAD = "https://celestrak.org/satcat/tle.php?CATNR={norad}&FORMAT=tle"
_TLE_SEARCH   = "https://celestrak.org/satcat/tle.php?SATNAME={name}&FORMAT=tle"

# In-memory cache for live TLEs
_live_cache: dict[str, dict] = {}


def _parse_tle_text(text: str) -> list[dict]:
    """Parse raw TLE text (groups of 3 lines) into list of dicts."""
    lines = [l.strip() for l in text.strip().splitlines() if l.strip()]
    results = []
    i = 0
    while i < len(lines):
        if lines[i].startswith("1 ") or lines[i].startswith("2 "):
            i += 1
            continue
        if i + 2 <= len(lines) - 1:
            name  = lines[i]
            line1 = lines[i + 1]
            line2 = lines[i + 2]
            if line1.startswith("1 ") and line2.startswith("2 "):
                cat_no = line1[2:7].strip()
                results.append({"name": name, "line1": line1, "line2": line2,
                                 "norad": cat_no, "stale": False})
                i += 3
                continue
        i += 1
    return results


async def fetch_tle(norad: str) -> dict:
    """
    Fetch TLE for a satellite by NORAD catalog number.

    Priority:
    1. In-memory live cache
    2. CelesTrak live fetch (accurate, current)
    3. Synthetic fallback with today's epoch (offline, shows realistic orbit)
    """
    if norad in _live_cache:
        return _live_cache[norad]

    url = _TLE_BY_NORAD.format(norad=norad)
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, follow_redirects=True)
            resp.raise_for_status()
        parsed = _parse_tle_text(resp.text)
        if parsed:
            _live_cache[norad] = parsed[0]
            return parsed[0]
        logger.warning("CelesTrak returned empty TLE for NORAD %s", norad)
    except Exception as exc:
        logger.warning("CelesTrak fetch failed for NORAD %s: %s — using synthetic TLE", norad, exc)

    if norad in _FALLBACK_TLES:
        return _FALLBACK_TLES[norad]

    raise ValueError(
        f"No TLE available for NORAD {norad}. "
        f"CelesTrak unreachable and no fallback TLE registered for this satellite."
    )


async def search_satellites(query: str, limit: int = 20) -> list[dict]:
    """
    Search CelesTrak by satellite name fragment.
    Falls back to searching the bundled fallback catalog when offline.
    """
    url = _TLE_SEARCH.format(name=query.upper().replace(" ", "%20"))
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(url, follow_redirects=True)
            resp.raise_for_status()
        parsed = _parse_tle_text(resp.text)
        if parsed:
            return parsed[:limit]
    except Exception as exc:
        logger.warning("CelesTrak search failed: %s — searching local fallback catalog", exc)

    q_lower = query.lower()
    return [v for v in _FALLBACK_TLES.values() if q_lower in v["name"].lower()][:limit]


def get_catalog() -> dict:
    return CATALOG
