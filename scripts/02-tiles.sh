#!/usr/bin/env bash
# 2. Build the vector map tiles (OpenMapTiles layout, which the app's map style is written for).
#    One tile set covers all our states: data/caliphate.mbtiles
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"
[ -s data/area.osm.pbf ] || { echo "data/area.osm.pbf is missing. Run ./scripts/01-download.sh first." >&2; exit 1; }

# Memory for the builder: about half the server's memory, at least 2 GB, at most 6 GB.
mem_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 4)
heap=$(( mem_gb / 2 )); [ "$heap" -lt 2 ] && heap=2; [ "$heap" -gt 6 ] && heap=6
echo "Building map tiles with Planetiler (memory: ${heap} GB)…"
docker run --rm --user="$(id -u)" -e JAVA_TOOL_OPTIONS="-Xmx${heap}g" -v "$PWD/data":/data \
  ghcr.io/onthegomap/planetiler:latest \
  --osm-path=/data/area.osm.pbf \
  --bounds="$BBOX" \
  --download \
  --storage=mmap \
  --minzoom=0 --maxzoom=14 \
  --output=/data/caliphate.new.mbtiles \
  --force
mv data/caliphate.new.mbtiles data/caliphate.mbtiles
ls -lh data/caliphate.mbtiles
