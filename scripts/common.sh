# Shared settings for the build scripts.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
[ -f .env ] && set -a && . ./.env && set +a
BBOX="${BBOX:-3.9,11.4,7.0,14.0}"
OSM_URL="${OSM_URL:-https://download.geofabrik.de/africa/nigeria-latest.osm.pbf}"
mkdir -p data
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'. $2" >&2; exit 1; }; }
