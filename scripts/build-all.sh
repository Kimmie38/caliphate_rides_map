#!/usr/bin/env bash
# Builds all the map data for Sokoto: tiles, fonts, routing and search.
# Run from the map-server folder:  ./scripts/build-all.sh
# Re-run whenever you want fresh OpenStreetMap data (e.g. monthly), then: docker compose restart
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/01-download.sh
./scripts/02-tiles.sh
./scripts/03-fonts.sh
./scripts/04-routing.sh
./scripts/05-search.sh
echo
echo "All map data built in ./data. Start the server with:  docker compose up -d --build"
