"""
FastAPI backend for the Satellite Interlink Simulation.

Endpoints
---------
GET  /api/catalog          – grouped list of popular satellites (name + NORAD)
GET  /api/tle/{norad}      – fetch single TLE from CelesTrak
GET  /api/search?q=…       – search CelesTrak by name fragment
POST /api/simulate         – propagate two satellites, return CZML + link data

Static
------
GET /                      – serve frontend/index.html
"""

import logging
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from .satellite_service import fetch_tle, get_catalog, search_satellites
from .propagator import propagate_and_build
from .link_budget import LinkConfig

logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="Satellite Interlink Simulation", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

FRONTEND_DIR = Path(__file__).parent.parent / "frontend"


# ---------------------------------------------------------------------------
# API routes
# ---------------------------------------------------------------------------

@app.get("/api/catalog")
async def api_catalog():
    """Return grouped satellite catalog for UI dropdowns."""
    return get_catalog()


@app.get("/api/tle/{norad}")
async def api_tle(norad: str):
    """Return TLE data for a NORAD catalog number."""
    try:
        tle = await fetch_tle(norad)
        return tle
    except Exception as exc:
        raise HTTPException(status_code=502, detail=str(exc))


@app.get("/api/search")
async def api_search(q: str = Query(..., min_length=2)):
    """Search CelesTrak catalog by satellite name fragment."""
    results = await search_satellites(q)
    return results


@app.post("/api/simulate")
async def api_simulate(body: dict):
    """
    Propagate two satellites and return CZML + link-budget timeline.

    Body parameters
    ---------------
    sat1        : NORAD catalog number (string)
    sat2        : NORAD catalog number (string)
    hours       : simulation duration in hours (default 3.0)
    step        : propagation step in seconds (default 30)
    link_config : optional dict of LinkConfig fields
    """
    sat1_id = str(body.get("sat1", ""))
    sat2_id = str(body.get("sat2", ""))
    if not sat1_id or not sat2_id:
        raise HTTPException(400, "sat1 and sat2 are required")
    if sat1_id == sat2_id:
        raise HTTPException(400, "sat1 and sat2 must be different satellites")

    hours = float(body.get("hours", 3.0))
    step  = int(body.get("step", 30))
    hours = max(0.5, min(24.0, hours))
    step  = max(10, min(300, step))

    raw_cfg = body.get("link_config", {})
    try:
        link_cfg = LinkConfig.from_dict(raw_cfg)
    except Exception as exc:
        raise HTTPException(400, f"Invalid link_config: {exc}")

    try:
        tle1 = await fetch_tle(sat1_id)
        tle2 = await fetch_tle(sat2_id)
    except Exception as exc:
        raise HTTPException(502, f"Failed to fetch TLEs: {exc}")

    try:
        result = propagate_and_build(tle1, tle2, hours=hours,
                                     step_s=step, link_cfg=link_cfg)
    except Exception as exc:
        logger.exception("Propagation error")
        raise HTTPException(500, f"Propagation failed: {exc}")

    return JSONResponse(content=result)


# ---------------------------------------------------------------------------
# Static / frontend
# ---------------------------------------------------------------------------

@app.get("/")
async def serve_frontend():
    index = FRONTEND_DIR / "index.html"
    if index.exists():
        return FileResponse(str(index))
    return JSONResponse({"error": "Frontend not found"}, status_code=404)


# Mount any extra static assets (CSS, JS bundles if added later)
if (FRONTEND_DIR / "static").exists():
    app.mount("/static", StaticFiles(directory=str(FRONTEND_DIR / "static")), name="static")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
