# Putting our map services on Render (free, for testing)

About 15 minutes of your time, plus 5–15 minutes of Render building.

## What needs a server, and what doesn't

| Map part | For testing | Notes |
|---|---|---|
| **Road routes** (fares, the green route line, arrival times) | **Our own server on Render's free plan** (this guide) | The public demo server the app uses today is slow and not allowed for real apps. |
| Map picture (streets, buildings) | OpenFreeMap, already set up in the app | Free, no key, allowed for commercial use. It can stay like this even after launch. |
| Place search | Photon's public server, already set up | Fine for testing. Places you add in the admin dashboard come from our own backend anyway. |

So for now we only deploy **routing**. It covers Sokoto city and about 30 km around it (Wamako, Kware,
Dange, the airport), which is small enough for the free plan.

---

## 1. Put this folder on GitHub

1. Unzip **caliphate-map-server.zip**.
2. On github.com: **+ → New repository** → name it `caliphate-map-server` → **Private** → **Create repository**.
3. Click **uploading an existing file**, drag **everything inside** the unzipped folder onto the page
   (so `render.yaml` is at the top level), then **Commit changes**.

## 2. Deploy on Render

1. On **https://dashboard.render.com** (same account as the backend): **+ New → Blueprint**.
2. Pick the `caliphate-map-server` repository.
3. Render reads `render.yaml` and shows one service, **caliphate-routing** (Docker, Frankfurt, **Free**).
   Click **Deploy Blueprint** (or **Apply**).
4. The first build takes 5–15 minutes: it downloads Nigeria from OpenStreetMap, cuts out Sokoto, and
   prepares the road network. Watch it in the service's **Logs**. When the service says **Live**, it's ready.

(If Blueprint asks for a card and you'd rather not: **+ New → Web Service** → the repository →
Language **Docker** → Dockerfile Path `./render/routing/Dockerfile`, Docker Build Context
`./render/routing` → Region **Frankfurt** → Instance **Free** → Advanced → Health Check Path
`/nearest/v1/driving/5.2310,13.0482` → **Deploy**.)

## 3. Check it

Use your service's address from the top of its Render page. If the name was free it's
`https://caliphate-routing.onrender.com`:

```
https://caliphate-routing.onrender.com/route/v1/driving/5.22601,13.06157;5.24538,13.04036?overview=false
```

That's Babbar Kasuwa to UDUS City Campus. You should see JSON starting with `{"code":"Ok"` and a
`"distance"` in metres (about 3,000).

## 4. Point the backend and the app at it

**Backend** (Render → `caliphate-api` → **Environment**): add

| Key | Value |
|---|---|
| `ROUTING_URL` | `https://caliphate-routing.onrender.com` (your address, no `/` at the end) |

Save; the API restarts. From then on fares are priced from real Sokoto roads, and the API keeps the
routing server awake while it's running.

**App**, in the `caliphate-rides` folder:
- `.env`: `EXPO_PUBLIC_ROUTING_URL=https://caliphate-routing.onrender.com`, then `npx expo start -c`.
- `eas.json` already has `EXPO_PUBLIC_ROUTING_URL` set to `https://caliphate-routing.onrender.com` in
  `base`. If Render gave you a different address, change it there too.

---

## Things to know about the free plan

- **It sleeps** after 15 minutes without requests, and takes about a minute to wake. The backend pings
  it every 10 minutes while the backend itself is awake, and wakes it when the backend starts, so the
  two wake up together. While it's waking, fares are estimated (a bit less accurate) and the route line
  is drawn straight; it corrects itself within a minute.
- **Free hours**: Render gives 750 free hours a month per account, shared by all free services. Because
  both services sleep when nobody is testing, that's plenty for testing.
- **Area**: trips are routed within roughly 4.95–5.55°E, 12.70–13.30°N. Rides that start in Sokoto
  city (the app's service area) are fine. For all of Sokoto State, see "Moving to a bigger server".

## Keeping the roads up to date

OpenStreetMap is edited every day. To pick up new roads: open the service on Render →
**Manual Deploy → Clear build cache & deploy** (monthly is plenty).

## If something goes wrong

| Problem | Fix |
|---|---|
| Build fails while downloading (`curl: (22)` or a timeout) | Geofabrik was busy. **Manual Deploy → Deploy latest commit** to try again. |
| The check in step 3 says `"code":"NoSegment"` | The points are outside the area. Use the example above, which is inside. |
| Out of memory / keeps restarting | Shouldn't happen with the city area. If you made the area bigger, pick a paid instance (see below). |
| The app still uses the demo server | Restart Expo with `npx expo start -c` after changing `.env`; builds read `eas.json`. |

## Moving to a bigger server later

- **All of Sokoto State**: in `render/routing/Dockerfile` change the `BBOX` line to
  `ARG BBOX=3.9,11.4,7.0,14.0`, and in the service's **Settings → Instance Type** pick at least
  **Standard (1 CPU, 2 GB)**. Commit; Render rebuilds.
- **Your own server** (Oracle Cloud free VM or a VPS) runs everything in this kit, including your own
  map tiles and search: see the main `README.md` and `docker-compose.yml`. Then change `ROUTING_URL`
  (backend) and `EXPO_PUBLIC_ROUTING_URL` (app) to the new address.
