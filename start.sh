#!/usr/bin/env bash
# Satellite Interlink Simulation — start script
# Usage:  ./start.sh [port]
set -e
PORT=${1:-8000}
cd "$(dirname "$0")"
pip install -q -r requirements.txt
echo "Starting ISL Simulation on http://localhost:${PORT}"
python3 -m uvicorn app.main:app --host 0.0.0.0 --port "${PORT}" --reload
