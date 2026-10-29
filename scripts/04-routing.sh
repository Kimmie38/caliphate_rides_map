#!/usr/bin/env bash
# 4. Road routing for Sokoto (OSRM, car profile). Gives every trip its distance, time and route line.
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"
mkdir -p data/osrm
cp data/sokoto.osm.pbf data/osrm/sokoto.osm.pbf
img=ghcr.io/project-osrm/osrm-backend:latest
run() { docker run --rm -t -v "$PWD/data/osrm":/data "$img" "$@"; }
echo "Preparing the road network…"
run osrm-extract -p /opt/car.lua /data/sokoto.osm.pbf
run osrm-partition /data/sokoto.osrm
run osrm-customize /data/sokoto.osrm
rm -f data/osrm/sokoto.osm.pbf
echo "Routing data ready."
