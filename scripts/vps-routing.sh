#!/usr/bin/env bash
# Road routing for all our states (Sokoto, Kano, Kaduna, FCT and Plateau), as the container
# "caliphate-routing" on the "proxy" network, port 5000: the same name and port the backend already
# uses (ROUTING_URL=http://caliphate-routing:5000), so nothing else needs changing.
#
#   ./scripts/vps-routing.sh             prepare the roads if needed, then (re)start
#   ./scripts/vps-routing.sh --rebuild   prepare again from data/area.osm.pbf (e.g. after a fresh download)
#
# The old routing keeps answering until the new road network is ready, then it's swapped in a few seconds.
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"

NAME=caliphate-routing
NETWORK="${NETWORK:-proxy}"
IMAGE=ghcr.io/project-osrm/osrm-backend:v26.10.0-debian

if ! docker network inspect "$NETWORK" >/dev/null 2>&1; then
  echo "There's no Docker network called '$NETWORK'. Check with: docker network ls" >&2
  exit 1
fi

if [ ! -s data/osrm/caliphate.osrm.mldgr ] || [ "${1:-}" = "--rebuild" ]; then
  echo "== Preparing the road network for 5 states (10–30 minutes) =="
  ./scripts/04-routing.sh
fi

echo "== Starting the routing server =="
docker pull -q "$IMAGE" >/dev/null
docker rm -f "$NAME" >/dev/null 2>&1 || true
# --mmap reads the roads from disk instead of copying them all into memory.
docker run -d --name "$NAME" --restart unless-stopped --network "$NETWORK" \
  -v "$PWD/data/osrm:/data:ro" \
  "$IMAGE" osrm-routed --algorithm mld --mmap --ip 0.0.0.0 --port 5000 --max-table-size 1000 /data/caliphate.osrm >/dev/null

check() { docker run --rm --network "$NETWORK" curlimages/curl -s "$1" 2>/dev/null; }
for _ in $(seq 1 30); do
  check "http://$NAME:5000/nearest/v1/driving/5.2310,13.0482" | grep -q '"Ok"' && break
  sleep 2
done

# A short trip in each city: the distance in metres (a number means routing works there).
trip() {
  check "http://$NAME:5000/route/v1/driving/$1;$2?overview=false" | grep -o '"distance":[0-9.]*' | head -1 | cut -d: -f2
}
echo "  Sokoto: $(trip 5.22601,13.06157 5.24538,13.04036) m"
echo "  Kano:   $(trip 8.5167,11.9964 8.5450,12.0000) m"
echo "  Kaduna: $(trip 7.4382,10.5222 7.4167,10.5050) m"
echo "  Abuja:  $(trip 7.4951,9.0579 7.4700,9.0400) m"
echo "  Jos:    $(trip 8.8920,9.9285 8.8583,9.8965) m"
echo
echo "If every city shows a distance, routing is ready. If one is empty: docker logs $NAME --tail 30"
