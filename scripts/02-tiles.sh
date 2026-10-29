#!/usr/bin/env bash
# 2. Build the vector map tiles (OpenMapTiles layout, which the app's map style is written for).
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"

echo "Building map tiles with Planetiler…"
docker run --rm --user="$(id -u)" -e JAVA_TOOL_OPTIONS="-Xmx3g" -v "$PWD/data":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --osm-path=/data/sokoto.osm.pbf \
  --bounds="$BBOX" \
  --download \
  --minzoom=0 --maxzoom=14 \
  --output=/data/sokoto.mbtiles \
  --force
ls -lh data/sokoto.mbtiles
