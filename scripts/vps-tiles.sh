#!/usr/bin/env bash
# Builds the Sokoto map tiles and label fonts, then starts the tile server (Martin) as the
# container "caliphate-tiles" on the "proxy" network, next to caliphate-routing.
# Nginx Proxy Manager then gives it the address https://tiles.caliphaterides.com.ng
#
#   ./scripts/vps-tiles.sh             build what's missing, then (re)start
#   ./scripts/vps-tiles.sh --rebuild   rebuild the tiles from data/sokoto.osm.pbf (e.g. after a fresh download)
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"

NAME=caliphate-tiles
NETWORK="${NETWORK:-proxy}"
IMAGE="${MARTIN_IMAGE:-ghcr.io/maplibre/martin:latest}"

if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  echo "There's no Docker network called '$NETWORK'. Check with: docker network ls" >&2
  exit 1
fi
if [ ! -f data/sokoto.osm.pbf ]; then
  echo "data/sokoto.osm.pbf is missing. Run ./scripts/01-download.sh first." >&2
  exit 1
fi

if [ ! -s data/sokoto.mbtiles ] || [ "${1:-}" = "--rebuild" ]; then
  echo "== Building the map tiles (5–15 minutes the first time: it also downloads coastline and lake data) =="
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
  -v "$PWD/data/sokoto.mbtiles:/data/sokoto.mbtiles:ro" \
  -v "$PWD/data/fonts:/fonts:ro" \
  "$IMAGE" /data/sokoto.mbtiles --font /fonts --listen-addresses 0.0.0.0:3000 >/dev/null

check() { docker run --rm --network "$NETWORK" curlimages/curl -s -o /dev/null -w "%{http_code}" "$1" 2>/dev/null || echo 000; }
for _ in $(seq 1 20); do
  [ "$(check http://$NAME:3000/health)" = "200" ] && break
  sleep 2
done

tiles=$(check "http://$NAME:3000/sokoto")
font=$(check "http://$NAME:3000/font/Noto%20Sans%20Regular/0-255")
echo "  map tiles: $tiles   label font: $font   (both should be 200)"
if [ "$tiles" = "200" ] && [ "$font" = "200" ]; then
  echo
  echo "The tile server is running."
  echo "Next: in Nginx Proxy Manager, point tiles.caliphaterides.com.ng at $NAME port 3000."
else
  echo
  echo "It didn't start properly. Last log lines:"
  docker logs "$NAME" --tail 30
  exit 1
fi
