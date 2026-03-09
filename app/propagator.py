"""
Orbit propagator using Skyfield's SGP4 implementation.

Produces:
  • CZML document for CesiumJS (satellite trails, interlink line, clock)
  • JSON link-timeline for Chart.js (window list, step-by-step margin)
"""

from __future__ import annotations

import logging
import math
from datetime import datetime, timedelta, timezone
from typing import Any

import numpy as np
from skyfield.api import load, EarthSatellite

from .link_budget import LinkConfig, compute_link_budget, max_range_km

logger = logging.getLogger(__name__)

# Skyfield timescale (loaded once at module import)
_TS = load.timescale()

# Colours [R, G, B, A]
SAT1_COLOUR = [255, 200, 0, 255]     # Gold
SAT2_COLOUR = [0, 191, 255, 255]     # Deep sky blue
LINK_ACTIVE_COLOUR = [0, 255, 100, 220]
LINK_INACTIVE_COLOUR = [255, 60, 60, 140]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _iso(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def _sky_to_datetime(t) -> datetime:
    y, mo, d, h, mi, s = t.utc
    return datetime(int(y), int(mo), int(d), int(h), int(mi),
                    int(s), tzinfo=timezone.utc)


def _build_cartesian_array(times_offset_s: list[float],
                            positions_km: np.ndarray) -> list[float]:
    """
    Interleave [t, x, y, z, t, x, y, z, …] in metres for CZML.
    positions_km shape: (3, N)
    """
    out: list[float] = []
    for i, t in enumerate(times_offset_s):
        out.append(t)
        out.append(float(positions_km[0, i]) * 1e3)
        out.append(float(positions_km[1, i]) * 1e3)
        out.append(float(positions_km[2, i]) * 1e3)
    return out


def _state_intervals(statuses: list[bool],
                     epoch: datetime,
                     step_s: int) -> tuple[list[str], list[str]]:
    """
    Return two lists of ISO interval strings: active windows, inactive windows.
    Each string: "start/end"
    """
    n = len(statuses)
    if n == 0:
        return [], []

    active, inactive = [], []
    i = 0
    while i < n:
        current = statuses[i]
        j = i + 1
        while j < n and statuses[j] == current:
            j += 1
        start_dt = epoch + timedelta(seconds=i * step_s)
        end_dt   = epoch + timedelta(seconds=(j - 1) * step_s + step_s)
        interval = f"{_iso(start_dt)}/{_iso(end_dt)}"
        (active if current else inactive).append(interval)
        i = j
    return active, inactive


def _show_czml(active_windows: list[str], epoch: datetime,
               duration_s: float, link_is_active: bool) -> list[dict]:
    """
    Build a CZML `show` interval array that covers the full simulation span.
    `link_is_active=True`  → show=True during active_windows, False elsewhere.
    `link_is_active=False` → show=True during inactive_windows, False elsewhere.
    """
    full_start = _iso(epoch)
    full_end   = _iso(epoch + timedelta(seconds=duration_s))
    full_interval = f"{full_start}/{full_end}"

    # Default show value (what most of the time looks like)
    default = not link_is_active  # inactive line: show by default; active line: hide by default

    result = [{"interval": full_interval, "boolean": default}]
    for w in active_windows:
        result.append({"interval": w, "boolean": link_is_active})
    return result


# ---------------------------------------------------------------------------
# Main CZML builder
# ---------------------------------------------------------------------------

def propagate_and_build(
    tle1: dict,
    tle2: dict,
    hours: float = 3.0,
    step_s: int = 30,
    link_cfg: LinkConfig | None = None,
) -> dict:
    """
    Propagate two satellites and produce CZML + link timeline JSON.

    Parameters
    ----------
    tle1, tle2 : dicts with keys name, line1, line2
    hours      : simulation duration
    step_s     : propagation step in seconds
    link_cfg   : link budget configuration

    Returns
    -------
    dict with keys:
        czml        – list of CZML packets ready to JSON-serialise
        link_data   – step-by-step link budget results for Chart.js
        summary     – human-readable summary dict
    """
    if link_cfg is None:
        link_cfg = LinkConfig()

    # Build skyfield objects
    sat1 = EarthSatellite(tle1["line1"], tle1["line2"], tle1["name"], _TS)
    sat2 = EarthSatellite(tle2["line1"], tle2["line2"], tle2["name"], _TS)

    # Start at current UTC time
    now_utc = datetime.now(timezone.utc).replace(microsecond=0)
    n_steps = max(2, int(hours * 3600 / step_s) + 1)
    offsets_s = [i * step_s for i in range(n_steps)]

    # Skyfield time array
    t_arr = _TS.utc(
        now_utc.year, now_utc.month, now_utc.day,
        now_utc.hour, now_utc.minute,
        [now_utc.second + i * step_s for i in range(n_steps)],
    )

    # ECI positions (km), shape (3, n_steps)
    pos1_km = sat1.at(t_arr).position.km
    pos2_km = sat2.at(t_arr).position.km

    # -------------------------------------------------------------------
    # Link budget at every step
    # -------------------------------------------------------------------
    link_results = []
    is_linked_flags: list[bool] = []

    for i in range(n_steps):
        r = compute_link_budget(
            pos1_km[:, i].tolist(),
            pos2_km[:, i].tolist(),
            link_cfg,
        )
        link_results.append({
            "t": offsets_s[i],
            "dt": _iso(now_utc + timedelta(seconds=offsets_s[i])),
            "is_linked": r.is_linked,
            "reason": r.reason,
            "range_km": round(r.range_km, 2),
            "fspl_db": round(r.fspl_db, 2),
            "received_power_dbm": round(r.received_power_dbm, 2),
            "noise_floor_dbm": round(r.noise_floor_dbm, 2),
            "link_margin_db": round(r.link_margin_db, 2),
            "los_clear": r.los_clear,
        })
        is_linked_flags.append(r.is_linked)

    n_linked = sum(is_linked_flags)
    link_fraction = n_linked / n_steps * 100.0

    # Active / inactive windows
    active_windows, inactive_windows = _state_intervals(
        is_linked_flags, now_utc, step_s
    )

    # -------------------------------------------------------------------
    # CZML assembly
    # -------------------------------------------------------------------
    epoch_str    = _iso(now_utc)
    end_str      = _iso(now_utc + timedelta(seconds=offsets_s[-1]))
    doc_interval = f"{epoch_str}/{end_str}"

    czml: list[dict[str, Any]] = []

    # Document / clock
    czml.append({
        "id": "document",
        "name": f"ISL: {tle1['name']} ↔ {tle2['name']}",
        "version": "1.0",
        "clock": {
            "interval": doc_interval,
            "currentTime": epoch_str,
            "multiplier": 60,
            "range": "LOOP_STOP",
            "step": "SYSTEM_CLOCK_MULTIPLIER",
        },
    })

    # --- Satellite 1 ---
    czml.append({
        "id": "sat1",
        "name": tle1["name"],
        "availability": doc_interval,
        "position": {
            "referenceFrame": "INERTIAL",
            "interpolationAlgorithm": "LAGRANGE",
            "interpolationDegree": 5,
            "epoch": epoch_str,
            "cartesian": _build_cartesian_array(offsets_s, pos1_km),
        },
        "point": {
            "pixelSize": 10,
            "color": {"rgba": SAT1_COLOUR},
            "outlineColor": {"rgba": [0, 0, 0, 200]},
            "outlineWidth": 1,
            "heightReference": "NONE",
            "scaleByDistance": {"nearFarScalar": [1.5e7, 1.5, 3e8, 1.0]},
        },
        "label": {
            "text": tle1["name"],
            "font": "bold 14px Helvetica",
            "fillColor": {"rgba": SAT1_COLOUR},
            "outlineColor": {"rgba": [0, 0, 0, 255]},
            "outlineWidth": 2,
            "style": "FILL_AND_OUTLINE",
            "pixelOffset": {"cartesian2": [14, 0]},
            "distanceDisplayCondition": {"distanceFarValue": 8e7},
        },
        "path": {
            "show": True,
            "width": 2,
            "material": {"solidColor": {"color": {"rgba": SAT1_COLOUR[:3] + [120]}}},
            "trailTime": hours * 3600 * 0.4,
            "leadTime": 0,
        },
    })

    # --- Satellite 2 ---
    czml.append({
        "id": "sat2",
        "name": tle2["name"],
        "availability": doc_interval,
        "position": {
            "referenceFrame": "INERTIAL",
            "interpolationAlgorithm": "LAGRANGE",
            "interpolationDegree": 5,
            "epoch": epoch_str,
            "cartesian": _build_cartesian_array(offsets_s, pos2_km),
        },
        "point": {
            "pixelSize": 10,
            "color": {"rgba": SAT2_COLOUR},
            "outlineColor": {"rgba": [0, 0, 0, 200]},
            "outlineWidth": 1,
            "heightReference": "NONE",
            "scaleByDistance": {"nearFarScalar": [1.5e7, 1.5, 3e8, 1.0]},
        },
        "label": {
            "text": tle2["name"],
            "font": "bold 14px Helvetica",
            "fillColor": {"rgba": SAT2_COLOUR},
            "outlineColor": {"rgba": [0, 0, 0, 255]},
            "outlineWidth": 2,
            "style": "FILL_AND_OUTLINE",
            "pixelOffset": {"cartesian2": [14, 0]},
            "distanceDisplayCondition": {"distanceFarValue": 8e7},
        },
        "path": {
            "show": True,
            "width": 2,
            "material": {"solidColor": {"color": {"rgba": SAT2_COLOUR[:3] + [120]}}},
            "trailTime": hours * 3600 * 0.4,
            "leadTime": 0,
        },
    })

    # --- Active interlink line (green, shown during link windows) ---
    czml.append({
        "id": "link-active",
        "name": "ISL Active",
        "show": _show_czml(active_windows, now_utc,
                           offsets_s[-1] + step_s, link_is_active=True),
        "polyline": {
            "positions": {"references": ["sat1#position", "sat2#position"]},
            "arcType": "NONE",
            "width": 3.0,
            "material": {
                "solidColor": {"color": {"rgba": LINK_ACTIVE_COLOUR}},
            },
        },
    })

    # --- Inactive link line (red dashed, shown when link is blocked) ---
    czml.append({
        "id": "link-inactive",
        "name": "ISL Blocked",
        "show": _show_czml(active_windows, now_utc,
                           offsets_s[-1] + step_s, link_is_active=False),
        "polyline": {
            "positions": {"references": ["sat1#position", "sat2#position"]},
            "arcType": "NONE",
            "width": 1.5,
            "material": {
                "polylineDash": {
                    "color": {"rgba": LINK_INACTIVE_COLOUR},
                    "dashLength": 16.0,
                    "dashPattern": 255,
                },
            },
        },
    })

    # -------------------------------------------------------------------
    # Summary / statistics
    # -------------------------------------------------------------------
    summary = {
        "sat1_name": tle1["name"],
        "sat2_name": tle2["name"],
        "epoch": epoch_str,
        "duration_hours": hours,
        "step_seconds": step_s,
        "n_steps": n_steps,
        "link_fraction_pct": round(link_fraction, 1),
        "n_link_windows": len(active_windows),
        "max_range_km": round(max_range_km(link_cfg), 0),
        "link_config": {
            "freq_ghz": link_cfg.freq_ghz,
            "tx_power_dbm": link_cfg.tx_power_dbm,
            "tx_gain_dbi": link_cfg.tx_gain_dbi,
            "rx_gain_dbi": link_cfg.rx_gain_dbi,
            "bandwidth_mhz": link_cfg.bandwidth_mhz,
            "noise_figure_db": link_cfg.noise_figure_db,
            "snr_req_db": link_cfg.snr_req_db,
            "min_margin_db": link_cfg.min_margin_db,
        },
        "active_windows": active_windows,
    }

    return {
        "czml": czml,
        "link_data": link_results,
        "summary": summary,
    }
