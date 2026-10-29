#!/usr/bin/env bash
# 1. Download Nigeria from OpenStreetMap and cut out Sokoto State.
. "$(dirname "$0")/common.sh"
need curl "Install it with: sudo apt install curl"
need osmium "Install it with: sudo apt install osmium-tool"

echo "Downloading Nigeria OpenStreetMap data…"
curl -L --fail -o data/nigeria.osm.pbf "$OSM_URL"

echo "Cutting out Sokoto State ($BBOX)…"
osmium extract --bbox "$BBOX" --strategy smart --overwrite -o data/sokoto.osm.pbf data/nigeria.osm.pbf
osmium fileinfo data/sokoto.osm.pbf | grep -E "Bounding|Size|Timestamp" || true
