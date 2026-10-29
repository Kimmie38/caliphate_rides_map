# Caliphate Rides road routing (OSRM) for Sokoto State, ready for Render.
# Render builds this image: it downloads Nigeria from OpenStreetMap, cuts out Sokoto State,
# prepares the road network, and serves routes on $PORT.

# ---- 1. Download Nigeria and cut out Sokoto State ----
FROM debian:trixie-slim AS extract
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates osmium-tool \
 && rm -rf /var/lib/apt/lists/*
ARG OSM_URL=https://download.geofabrik.de/africa/nigeria-latest.osm.pbf
# west,south,east,north: Sokoto State with a margin
ARG BBOX=3.9,11.4,7.0,14.0
WORKDIR /data
RUN curl -L --fail -o nigeria.osm.pbf "$OSM_URL" \
 && osmium extract --bbox "$BBOX" --strategy smart -o sokoto.osm.pbf nigeria.osm.pbf \
 && rm nigeria.osm.pbf

# ---- 2. Prepare the road network (car profile) ----
FROM ghcr.io/project-osrm/osrm-backend:latest AS prepare
COPY --from=extract /data/sokoto.osm.pbf /data/sokoto.osm.pbf
RUN osrm-extract -p /opt/car.lua /data/sokoto.osm.pbf \
 && osrm-partition /data/sokoto.osrm \
 && osrm-customize /data/sokoto.osrm \
 && rm /data/sokoto.osm.pbf

# ---- 3. Serve routes ----
FROM ghcr.io/project-osrm/osrm-backend:latest
COPY --from=prepare /data /data
ENV PORT=10000
EXPOSE 10000
CMD ["sh", "-c", "exec osrm-routed --algorithm mld --ip 0.0.0.0 --port ${PORT:-10000} --max-table-size 1000 /data/sokoto.osrm"]
