#!/usr/bin/env bash
# 5. Place search (Photon), built from GraphHopper's Nigeria export, Nigeria only.
. "$(dirname "$0")/common.sh"
need docker "Install Docker: https://docs.docker.com/engine/install/"
need zstd "Install it with: sudo apt install zstd"
if [ -z "${PHOTON_DUMP_URL:-}" ]; then
  echo "Set PHOTON_DUMP_URL in .env first (see .env.example)." >&2
  exit 1
fi
mkdir -p data/photon
echo "Downloading the search data…"
curl -L --fail -o data/photon/dump.jsonl.zst "$PHOTON_DUMP_URL"
echo "Building the search index…"
docker compose build photon
rm -rf data/photon/photon_data
zstd --stdout -d data/photon/dump.jsonl.zst | docker compose run --rm -T photon \
  import -import-file - -country-codes ng -languages en,ha
rm -f data/photon/dump.jsonl.zst
echo "Search data ready."
