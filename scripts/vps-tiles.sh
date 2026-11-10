#!/usr/bin/env bash
# Builds the map tiles for all our states (Sokoto, Kano, Kaduna, FCT and Plateau) and the label fonts,
# then starts the tile server (Martin) as the container "caliphate-tiles" on the "proxy" network.
# Nginx Proxy Manager gives it the address https://tiles.caliphaterides.com.ng
# The tiles answer at /caliphate (new app versions) and /sokoto (app versions already on phones).
#
#   ./scripts/vps-tiles.sh             build what's missing, then (re)start
#   ./scripts/vps-tiles.sh --rebuild   rebuild the tiles from data/area.osm.pbf (e.g. after a fresh download)
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"

NAME=caliphate-tiles
NETWORK="${NETWORK:-proxy}"
IMAGE="${MARTIN_IMAGE:-ghcr.io/maplibre/martin:latest}"

if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  echo "There's no Docker network called '$NETWORK'. Check with: docker network ls" >&2
  exit 1
fi
if [ ! -f data/area.osm.pbf ]; then
  echo "data/area.osm.pbf is missing. Run ./scripts/01-download.sh first." >&2
  exit 1
fi

# The world's sea coastlines come from osmdata.openstreetmap.de, which some servers can't reach.
# None of our states has a coast, so a tiny stand-in file gives the same map.
mkdir -p data/sources
if [ ! -s data/sources/water-polygons-split-3857.zip ] && ! curl -s -o /dev/null --max-time 15 -r 0-0 https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip; then
  echo "== osmdata.openstreetmap.de can't be reached: using a stand-in for the sea coastlines (our states have no coast) =="
  python3 scripts/make-water.py data/sources/water-polygons-split-3857.zip
fi

if [ ! -s data/caliphate.mbtiles ] || [ "${1:-}" = "--rebuild" ]; then
  echo "== Building the map tiles for 5 states (20–60 minutes; the first time it also downloads lake data) =="
  ./scripts/02-tiles.sh
fi
if [ ! -s data/fonts/NotoSans-Regular.ttf ] || [ ! -s data/fonts/NotoSans-Bold.ttf ]; then
  echo "== Downloading the label fonts =="
  ./scripts/03-fonts.sh
fi

echo "== Starting the tile server =="
docker pull -q "$IMAGE" >/dev/null
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" --restart unless-stopped --network "$NETWORK" \
  -v "$PWD/data/caliphate.mbtiles:/data/caliphate.mbtiles:ro" \
  -v "$PWD/data/fonts:/fonts:ro" \
  -v "$PWD/martin.yaml:/config/martin.yaml:ro" \
  "$IMAGE" --config /config/martin.yaml >/dev/null

check() { docker run --rm --network "$NETWORK" curlimages/curl -s -o /dev/null -w "%{http_code}" "$1" 2>/dev/null || echo 000; }
for _ in $(seq 1 20); do
  [ "$(check http://$NAME:3000/health)" = "200" ] && break
  sleep 2
done

tiles=$(check "http://$NAME:3000/caliphate")
old=$(check "http://$NAME:3000/sokoto")
font=$(check "http://$NAME:3000/font/Noto%20Sans%20Regular/0-255")
# A street-level tile in each city (zoom 14): Sokoto, Kano, Kaduna, Abuja, Jos
cities=""
for xy in 8430/7592 8583/7641 8529/7710 8528/7777 8595/7739; do cities="$cities $(check "http://$NAME:3000/caliphate/14/$xy")"; done
echo "  map tiles: $tiles   old address (/sokoto): $old   label font: $font   (all should be 200)"
echo "  city tiles (Sokoto Kano Kaduna Abuja Jos):$cities   (200 = has streets)"
if [ "$tiles" = "200" ] && [ "$old" = "200" ] && [ "$font" = "200" ]; then
  echo
  echo "The tile server is running."
  echo "Next: in Nginx Proxy Manager, point tiles.caliphaterides.com.ng at $NAME port 3000."
else
  echo
  echo "It didn't start properly. Last log lines:"
  docker logs "$NAME" --tail 30
  exit 1
fi
