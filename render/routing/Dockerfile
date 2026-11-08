# Caliphate Rides road routing (OSRM) for Render.
# Render builds this image: it downloads Nigeria from OpenStreetMap, cuts out the area below,
# prepares the road network, and serves routes on $PORT.
#
# The default area is Sokoto city and about 30 km around it (Wamako, Kware, Dange, the airport),
# small enough for Render's FREE plan (512 MB). For all of Sokoto State, change BBOX to
# 3.9,11.4,7.0,14.0 and use at least the 1 CPU / 2 GB plan.

# ---- 1. Download Nigeria and cut out the area ----
FROM debian:trixie-slim AS extract
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates osmium-tool \
 && rm -rf /var/lib/apt/lists/*
ARG OSM_URL=https://download.geofabrik.de/africa/nigeria-latest.osm.pbf
# west,south,east,north
ARG BBOX=4.95,12.70,5.55,13.30
WORKDIR /data
RUN curl -L --fail --retry 3 --retry-delay 10 -o nigeria.osm.pbf "$OSM_URL" \
 && osmium extract --bbox "$BBOX" -o area.osm.pbf nigeria.osm.pbf \
 && rm nigeria.osm.pbf \
 && osmium fileinfo area.osm.pbf | head -20

# ---- 2. Prepare the road network (car profile) ----
FROM ghcr.io/project-osrm/osrm-backend:v26.10.0-debian AS prepare
COPY --from=extract /data/area.osm.pbf /data/sokoto.osm.pbf
RUN osrm-extract -p /opt/car.lua /data/sokoto.osm.pbf \
 && osrm-partition /data/sokoto.osrm \
 && osrm-customize /data/sokoto.osrm \
 && rm /data/sokoto.osm.pbf

# ---- 3. Serve routes ----
FROM ghcr.io/project-osrm/osrm-backend:v26.10.0-debian
COPY --from=prepare /data /data
ENV PORT=10000
EXPOSE 10000
# --mmap reads the road network from disk instead of copying it into memory, so it fits small plans.
CMD ["sh", "-c", "exec osrm-routed --algorithm mld --mmap --ip 0.0.0.0 --port ${PORT:-10000} --max-table-size 1000 /data/sokoto.osrm"]
