# Deploying our map services on Render

Start with **routing**: it's what prices every trip and draws the green route line, and the
public demo server the app uses today is only for testing. Map tiles can stay on OpenFreeMap
(free, unlimited, commercial use allowed) and search on Photon's public server for now.

## 1. Put this folder on GitHub

1. On github.com: **New repository** → name it `caliphate-map-server` → Private → **Create**.
2. Upload the contents of this folder (`caliphate-map-server`): on the new repo page choose
   **uploading an existing file**, drag everything in, and **Commit changes**.
   Or from a terminal inside this folder:
   ```bash
   git init && git add -A && git commit -m "Caliphate map server"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/caliphate-map-server.git
   git push -u origin main
   ```

## 2. Deploy on Render

1. Sign in at render.com (you can sign in with GitHub).
2. **New** → **Blueprint** → connect GitHub if asked → pick `caliphate-map-server`.
3. Render reads `render.yaml` and shows one service, **caliphate-routing**
   (Docker, Frankfurt, 0.5 CPU / 512 MB). Click **Deploy Blueprint**.
4. The first build takes a while: it downloads Nigeria from OpenStreetMap, cuts out
   Sokoto State and prepares the road network. Watch it under the service's **Events / Logs**.
   When it says **Live**, it's ready.

## 3. Check it

Open this in a browser (use your service's address from the top of its Render page):

```
https://caliphate-routing.onrender.com/route/v1/driving/5.22601,13.06157;5.24538,13.04036?overview=false
```

That's Babbar Kasuwa to UDUS City Campus. You should see JSON starting with `{"code":"Ok"` and a
`"distance"` in metres.

## 4. Point the app at it

- **Builds from EAS:** `eas.json` already has `EXPO_PUBLIC_ROUTING_URL` in its `base` profile.
  If Render gave your service a different address, change it there. Commit, then build.
- **Testing with `npx expo start`:** add the same line to `.env`:
  ```
  EXPO_PUBLIC_ROUTING_URL=https://caliphate-routing.onrender.com
  ```
  then restart with `npx expo start -c` (the `-c` makes it pick up the change).

## Keeping it fresh

OpenStreetMap is edited every day. To pick up new Sokoto roads, open the service on Render and
click **Manual Deploy → Clear build cache & deploy** (monthly is plenty).

## If something goes wrong

- **Build fails while downloading:** Geofabrik was busy. Redeploy.
- **"Out of memory" / the service keeps restarting:** in the service's **Settings → Instance Type**,
  pick 1 CPU / 2 GB.
- **The app still uses the demo server:** the address must be in `eas.json` (for EAS builds) or
  `.env` + `npx expo start -c` (for testing). Apps only read these when they're built or started.
