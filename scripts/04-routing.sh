#!/usr/bin/env bash
# 4. Road routing for our states (OSRM, car profile). Gives every trip its distance, time and route line.
#    Only roads (and turn rules) are kept first, so it needs far less memory.
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"
need osmium "Install it with: sudo apt install osmium-tool"
[ -s data/area.osm.pbf ] || { echo "data/area.osm.pbf is missing. Run ./scripts/01-download.sh first." >&2; exit 1; }

rm -rf data/osrm.new && mkdir -p data/osrm.new
echo "Keeping only roads…"
osmium tags-filter data/area.osm.pbf w/highway r/type=restriction --overwrite -o data/osrm.new/caliphate.osm.pbf
ls -lh data/osrm.new/caliphate.osm.pbf

img=ghcr.io/project-osrm/osrm-backend:v26.10.0-debian
run() { docker run --rm -t -v "$PWD/data/osrm.new":/data "$img" "$@"; }
echo "Preparing the road network (10–30 minutes)…"
run osrm-extract -p /opt/car.lua /data/caliphate.osm.pbf
run osrm-partition /data/caliphate.osrm
run osrm-customize /data/caliphate.osrm
rm -f data/osrm.new/caliphate.osm.pbf

# Swap in the new road network only once it's complete.
rm -rf data/osrm.old
[ -d data/osrm ] && mv data/osrm data/osrm.old
mv data/osrm.new data/osrm
rm -rf data/osrm.old
echo "Routing data ready: data/osrm/caliphate.osrm"
