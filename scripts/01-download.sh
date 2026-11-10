#!/usr/bin/env bash
# 1. Download Nigeria from OpenStreetMap and cut out our states (regions.geojson).
. "$(dirname "$0")/common.sh"
need curl "Install it with: sudo apt install curl"
need osmium "Install it with: sudo apt install osmium-tool"

# ./scripts/01-download.sh --cut-only   uses the Nigeria file already downloaded (no new download)
if [ "${1:-}" = "--cut-only" ] && [ -s data/nigeria.osm.pbf ]; then
  echo "Using the Nigeria file already here ($(du -h data/nigeria.osm.pbf | cut -f1))."
else
  echo "Downloading Nigeria OpenStreetMap data (about 800 MB)…"
  curl -L --fail -o data/nigeria.osm.pbf.part "$OSM_URL"
  mv data/nigeria.osm.pbf.part data/nigeria.osm.pbf
fi

echo "Cutting out Sokoto, Kano, Kaduna, FCT (Abuja) and Plateau…"
osmium extract --polygon "$REGIONS" --strategy smart --overwrite -o data/area.osm.pbf data/nigeria.osm.pbf
osmium fileinfo data/area.osm.pbf | grep -E "Bounding|Size|Timestamp" || true
ls -lh data/area.osm.pbf
