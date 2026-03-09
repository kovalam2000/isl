# Satellite Interlink Simulation

A full 3D inter-satellite link (ISL) simulator with a Python backend and
CesiumJS web frontend. Select any two satellites from the live CelesTrak
catalog, configure a Ka-band link budget, and watch the simulation run in
real time on an animated 3D globe.

---

## Quick start

```bash
pip install -r requirements.txt
./start.sh          # opens on http://localhost:8000
```

---

## What it does

| Feature | Detail |
|---|---|
| Orbit propagation | Skyfield SGP4 — same model used by space agencies |
| TLE source | CelesTrak live fetch; falls back to synthetic TLEs offline |
| Satellites | 24 pre-catalogued across 6 categories; free-text search for any NORAD ID |
| 3D globe | CesiumJS — animated orbits, trail paths, real-time ISL line |
| ISL line | Green solid = active link · Red dashed = Earth-blocked or out of range |
| Link budget | Ka-band: FSPL, antenna gain, noise floor, link margin — all configurable |
| Time controls | Play/pause + speed slider 1× – 1800×, driven by CesiumJS CZML clock |
| Timeline chart | Link margin [dB] vs time (Chart.js) |

---

## Project structure

```
.
├── app/
│   ├── main.py               FastAPI app — API + static frontend
│   ├── satellite_service.py  CelesTrak TLE fetch + 24-satellite offline fallback
│   ├── propagator.py         Skyfield SGP4 propagation → CZML generation
│   └── link_budget.py        Ka-band ISL link budget + Earth-occultation LOS check
├── frontend/
│   └── index.html            CesiumJS 3D globe + Chart.js timeline (no build step)
├── requirements.txt
└── start.sh
```

---

## API

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/catalog` | Grouped satellite catalog for UI dropdowns |
| `GET` | `/api/tle/{norad}` | Fetch single TLE from CelesTrak |
| `GET` | `/api/search?q=…` | Search CelesTrak by name fragment |
| `POST` | `/api/simulate` | Propagate two satellites → CZML + link-budget timeline |

### `/api/simulate` body

```json
{
  "sat1": "25544",
  "sat2": "44058",
  "hours": 3.0,
  "step": 30,
  "link_config": {
    "freq_ghz": 26,
    "tx_power_dbm": 40,
    "tx_gain_dbi": 40,
    "rx_gain_dbi": 40,
    "bandwidth_mhz": 500,
    "noise_figure_db": 5,
    "snr_req_db": 10,
    "min_margin_db": 3
  }
}
```

---

## Link detection physics

Two independent checks must both pass:

### 1. Geometric LOS — Earth occultation

The minimum distance from Earth's centre to the satellite-to-satellite line
segment is compared against `R_earth + 100 km` (atmosphere margin).

### 2. Ka-band link budget

```
FSPL  = 20·log10(4π·d·f / c)       free-space path loss grows with d² and f²
P_rx  = P_tx + G_tx + G_rx − FSPL  received power [dBm]
N     = kT + 10·log10(B) + NF      noise floor [dBm]
margin = P_rx − N − SNR_req

Link ACTIVE when margin ≥ min_margin AND LOS is clear
```

**Why does the signal fail?**

- **Earth occultation** — Earth's body blocks the path. Dominant for LEO
  satellites on opposite sides of the globe.
- **Free-space path loss** — power falls as 1/d². At 26 GHz, 5 000 km →
  FSPL ≈ 195 dB. Every +6 dB of antenna gain doubles the maximum range.
- **Noise floor** — at 500 MHz BW the noise floor is ≈ −87 dBm; received
  power must exceed it by `SNR_req + margin`.

With default 40 dBi antennas the max ISL range is **≈ 2 600 km**.
50 dBi phased arrays extend that to ≈ 12 000 km.

---

## Satellite categories

| Category | Altitude | Examples |
|---|---|---|
| Space Stations | ~400 km | ISS, Tiangong |
| Starlink | ~550 km | STARLINK-1007, -1008 … |
| OneWeb | ~1 200 km | ONEWEB-0010, -0012 … |
| Earth Observation | ~705 km | TERRA, AQUA, Sentinel-2 |
| Navigation (MEO) | ~20 000 km | GPS BIIF, Galileo, GLONASS |
| Geostationary | ~35 800 km | GOES-16, GOES-18, Intelsat 901 |

---

## History

The original MATLAB simulation (David Puig Puig, ESEIAAT-UPC, 2019–2021)
is preserved in full at:

```
branch:  archive/matlab-original
tag:     v0.1.0-matlab
```
