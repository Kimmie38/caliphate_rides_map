# Shared settings for the build scripts.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
[ -f .env ] && set -a && . ./.env && set +a
# The states we build (regions.geojson): Sokoto, Kano, Kaduna, FCT (Abuja) and Plateau, each with a margin.
REGIONS="${REGIONS:-regions.geojson}"
# The box around all of them (west,south,east,north), for the tile builder.
BBOX="${BBOX:-3.9,8.2,10.7,14.0}"
OSM_URL="${OSM_URL:-https://download.geofabrik.de/africa/nigeria-latest.osm.pbf}"
mkdir -p data
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'. $2" >&2; exit 1; }; }
