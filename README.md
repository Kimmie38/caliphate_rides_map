# Caliphate Rides map server

Our own map for Sokoto: the map itself, routes and place search, all from OpenStreetMap data, on a server we control. No Google, no per-request fees, no keys.

| Part | What it does | Built with |
|---|---|---|
| **Map tiles** | The map riders and drivers see. The app draws it in our own white-and-green style. | [Planetiler](https://github.com/onthegomap/planetiler) builds the tiles, [Martin](https://github.com/maplibre/martin) serves them |
| **Fonts** | Letters for street and place names on the map | Noto Sans, served by Martin |
| **Routing** | Road distance, time and the route line for every trip (and so the fare) | [OSRM](https://github.com/Project-OSRM/osrm-backend) |
| **Search** | "Where to?" search for streets and places | [Photon](https://github.com/komoot/photon) |
| **HTTPS** | One secure address in front of everything | [Caddy](https://caddyserver.com) (free certificate, automatic) |

**Quickest start: deploy just the routing on Render** with the ready-made setup in `render/` (see [render/README.md](render/README.md)). The full kit below runs everything on your own server.

Until this is running, the app uses free public servers for the same things (OpenFreeMap, the OSRM demo server and Photon's public server). They're fine for testing but have usage limits and no guarantees, so **switch to this server before launch**.

## What you need

- A Linux server (Ubuntu 24.04 is easiest). For Sokoto State: **4 CPU cores, 8 GB RAM, 40 GB SSD** is plenty. Any VPS provider works. A Lagos data centre keeps the map fast for riders.
- A domain name for the map, e.g. `maps.caliphaterides.ng`, with its DNS **A record pointing at the server**.
- Installed on the server: Docker, plus these small tools:
  ```bash
  sudo apt update && sudo apt install -y curl osmium-tool zstd
  # Docker: https://docs.docker.com/engine/install/ubuntu/
  ```

## Set up (about 30–60 minutes, mostly waiting)

1. **Copy this folder to the server** and open it:
   ```bash
   cd caliphate-map-server
   cp .env.example .env
   nano .env
   ```
   Set `MAP_DOMAIN`. For `PHOTON_DUMP_URL`, open
   <https://download1.graphhopper.com/public/africa/nigeria/index.html>, find the newest `photon-dump-…jsonl.zst` file for Photon 1.x, and paste its link.

2. **Build the map data** (downloads Nigeria from OpenStreetMap and cuts out Sokoto State):
   ```bash
   ./scripts/build-all.sh
   ```
   You can also run the steps one by one (`01-download.sh` … `05-search.sh`) if one fails.

3. **Start the server:**
   ```bash
   docker compose up -d --build
   ```

4. **Check it works:**
   ```bash
   ./scripts/check.sh
   ```
   You should see `200` for tiles and fonts, a distance for the route (Babbar Kasuwa to UDUS City Campus), and a place name for the search.

## On a VPS that already runs Nginx Proxy Manager (our Contabo server)

Caddy isn't used there (Nginx Proxy Manager already owns ports 80 and 443). Each part runs as its own
container on the `proxy` network and gets its own address in Nginx Proxy Manager:

| Address | Container | Port | Started by |
|---|---|---|---|
| `routing.caliphaterides.com.ng` | `caliphate-routing` | 5000 | `./scripts/vps-routing.sh` |
| `tiles.caliphaterides.com.ng` | `caliphate-tiles` | 3000 | `./scripts/vps-tiles.sh` |

The map covers **Sokoto, Kano, Kaduna, FCT (Abuja) and Plateau** (the boxes in `regions.geojson`).

```bash
cd /opt/caliphate_rides_map
git pull
chmod +x scripts/*.sh
free -h && df -h .                 # need about 4 GB of memory and 15 GB of free disk
./scripts/01-download.sh           # Nigeria from OpenStreetMap, cut to our 5 states
./scripts/vps-tiles.sh --rebuild   # map tiles: 20–60 minutes
./scripts/vps-routing.sh --rebuild # road routing: 10–30 minutes
```

Both scripts finish by testing each city. The old map and routing keep working while the new ones build.
Run the long builds inside `tmux` (or `screen`) so they carry on if your connection drops.

Then add a Cloudflare A record `tiles` → the server's IP (DNS only), and in Nginx Proxy Manager a
proxy host `tiles.caliphaterides.com.ng` → `caliphate-tiles` port `3000` with an SSL certificate.

App (`.env` and `eas.json`). The tiles answer at `/caliphate`; `/sokoto` still works for app versions already on phones:

```bash
EXPO_PUBLIC_MAP_TILES_URL=https://tiles.caliphaterides.com.ng/caliphate
EXPO_PUBLIC_MAP_GLYPHS_URL=https://tiles.caliphaterides.com.ng/font/{fontstack}/{range}
```

Backend `.env` (the admin's "Map places" page):

```bash
MAP_TILES_URL=https://tiles.caliphaterides.com.ng/caliphate
MAP_GLYPHS_URL=https://tiles.caliphaterides.com.ng/font/{fontstack}/{range}
```

Outside our states the app switches to the public map by itself, so testers elsewhere still see streets.
Monthly refresh: `./scripts/01-download.sh && ./scripts/vps-tiles.sh --rebuild && ./scripts/vps-routing.sh --rebuild`.

**Adding another state later:** add its box (west, south, east, north) to `regions.geojson`, widen `BBOX` in
`.env` to include it, run the three commands above, and add the city to the backend and app (`CITIES`).

## Point the app at it

In the app's `.env` (replace the domain with yours):

```bash
EXPO_PUBLIC_MAP_TILES_URL=https://maps.caliphaterides.ng/tiles/caliphate
EXPO_PUBLIC_MAP_GLYPHS_URL=https://maps.caliphaterides.ng/tiles/font/{fontstack}/{range}
EXPO_PUBLIC_ROUTING_URL=https://maps.caliphaterides.ng/osrm
EXPO_PUBLIC_SEARCH_URL=https://maps.caliphaterides.ng/photon
```

Then rebuild the app. The backend should use the same `ROUTING_URL` when it prices trips, so the fare the rider sees and the fare the backend charges always match.

## Keeping the map fresh

OpenStreetMap is edited every day. To pick up new roads and places, rebuild once a month:

```bash
./scripts/build-all.sh && docker compose restart
```

You can also improve Sokoto's map yourself: anyone can add missing streets, markets and landmarks at <https://www.openstreetmap.org>. Your edits show up in our map at the next rebuild.

## Addresses on the server

| Address | What |
|---|---|
| `/tiles/caliphate` | Map tiles (TileJSON; `/tiles/sokoto` still works) |
| `/tiles/font/{fontstack}/{range}` | Label fonts |
| `/osrm/route/v1/driving/{lng},{lat};{lng},{lat}` | A route |
| `/photon/api?q=…` | Place search |
| `/photon/reverse?lat=…&lon=…` | What's at a point |

## Notes

- **Area:** `BBOX` in `.env` covers Sokoto State with a margin. To add another state later, widen it and rebuild.
- **Keke routing:** routes use OSRM's car profile. If kekes in Sokoto use roads or shortcuts cars can't, we can add a keke profile later.
- **Credit:** the map must show "© OpenStreetMap contributors". The app does this with the small (i) button on the map.
