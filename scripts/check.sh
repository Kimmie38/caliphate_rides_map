#!/usr/bin/env bash
# Checks the running map server from the outside: tiles, fonts, a route and a search.
. "$(dirname "$0")/common.sh"
host="https://${MAP_DOMAIN:?Set MAP_DOMAIN in .env}"
ok() { printf "  %-8s %s\n" "$1" "$2"; }
code() { curl -s -o /dev/null -w "%{http_code}" "$1"; }
echo "Checking $host"
ok tiles  "$(code "$host/tiles/sokoto") (TileJSON)"
ok fonts  "$(code "$host/tiles/font/Noto%20Sans%20Regular/0-255") (label font)"
# Babbar Kasuwa → UDUS City Campus
ok route  "$(curl -s "$host/osrm/route/v1/driving/5.22601,13.06157;5.24538,13.04036?overview=false" | grep -o '"distance":[0-9.]*' | head -1)"
ok search "$(curl -s "$host/photon/api?q=kasuwa&limit=1" | grep -o '"name":"[^"]*"' | head -1)"
