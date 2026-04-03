# TCAMT Lite — Frontend (`tcamt-lite-client`)

AngularJS / Grunt / Bower client. This document describes how to run it **with Docker** (recommended) and **on the host** with Node.js.

---

## Expected toolchain

| Tool | Version (see `package.json` `engines` and `.nvmrc`) |
|------|---------------------------------------------------|
| Node.js | **13.12.0** |
| npm | **6.14.4** (bundled with that Node release) |

---

## Why Docker?

- Matches the toolchain without installing old Node, Python, or build tools on your machine.
- **`bower_components/` is gitignored** — a fresh clone does not include Bower packages. The Docker setup installs them into **named volumes** so you do not depend on a local `bower_components` folder.
- **`npm install`** may compile native addons; the image includes **Python 3**, **gcc/g++**, **make**, and **libssl-dev** for **node-gyp**.

---

## Prerequisites (Docker workflow)

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose v2) **running**
- On **Apple Silicon**, images use **`platform: linux/amd64`** in `docker-compose.yml` for compatibility with the Node 13 base image (may run under emulation).

---

## Quick start (Docker)

From this directory (`tcamt-lite-client`):

```bash
npm run docker:up
```

Then open **http://localhost:9000**.

- **Port 9000** — Grunt `connect` dev server  
- **Port 35729** — LiveReload (browser extension or injected script, depending on setup)

Stop containers:

```bash
npm run docker:down
```

### Full stack with Tomcat (`tcamt-deploy`)

When you run **`../tcamt-deploy/docker compose up`**, the frontend container receives:

- **`TCAMT_BACKEND_URL`** — Tomcat base URL (e.g. `http://tcamt-webapp:8080` in Compose)
- **`TCAMT_CONTEXT_PATH`** — WAR context path (default **`tcamt`**, matches `tcamt.war` on Tomcat)

Grunt then **proxies** ` /api/*` and `/j_spring*` to `/{context}/…` on Tomcat and rewrites **Set-Cookie** paths so sessions work from **http://localhost:9000**. Use the **Grunt** URL in the browser, not only Tomcat.

---

## Docker Compose services

`docker-compose.yml` defines **two** services. Use **one at a time** (same ports).

### `tcamt-client` (default for `npm run docker:up`)

- Runs the built image.
- Mounts only **named volumes**:
  - `tcamt_node_modules` → `/app/node_modules`
  - `tcamt_bower_components` → `/app/bower_components`
- Does **not** bind-mount your source tree. Best for: trying the app, CI-style runs, or a published image.

### `tcamt-client-dev`

```bash
npm run docker:up:dev
```

- Bind-mounts the **current directory** to `/app` so edits on the host show up in the container.
- Still uses the **same named volumes** for `node_modules` and `bower_components`, mounted **after** the bind mount so:
  - You are **not** required to have `bower_components` on disk (it stays in the volume).
  - You avoid “empty `node_modules` on the host” problems.

`CHOKIDAR_USEPOLLING=1` helps file watching when using bind mounts on macOS/Windows.

---

## What runs inside the container

1. **`docker-entrypoint.sh`** (see repo) runs before the main command:
   - If `node_modules` is missing or empty → **`npm install`**
   - If `bower_components` is missing or empty → **`bower install --allow-root`**
2. **`npx grunt serve`** — dev server, Sass (Dart Sass via `grunt-shell`), watch, LiveReload.

Environment (set in `Dockerfile` / Compose):

- `GRUNT_CONNECT_HOSTNAME=0.0.0.0` — listen on all interfaces (required to reach the app from the host).
- `GRUNT_NO_OPEN=1` — do not try to launch a browser inside the container.

---

## npm scripts (Docker)

| Script | Command |
|--------|---------|
| `npm run docker:build` | `docker build -t tcamt-prm/tcamt-client:dev .` |
| `npm run docker:up` | `docker compose up tcamt-client --build` |
| `npm run docker:up:dev` | `docker compose up tcamt-client-dev --build` |
| `npm run docker:down` | `docker compose down` |
| `npm run docker:clean-volumes` | `docker compose down -v` (removes named volumes) |
| `npm run docker:run` | One-off container with explicit named volumes (no Compose) |

---

## After changing dependencies

If you change **`package.json`**, **`package-lock.json`**, or **`bower.json`**, reset the Docker volumes and rebuild so installs are not stale:

```bash
npm run docker:clean-volumes
npm run docker:up
```

Or for dev:

```bash
npm run docker:clean-volumes
npm run docker:up:dev
```

---

## Publishing this folder as a Git repo

You should commit:

- Application sources, `package.json`, `package-lock.json`, `bower.json`
- `Dockerfile`, `docker-compose.yml`, `docker-entrypoint.sh`, `Gruntfile.js`, etc.

You typically **do not** commit `node_modules/` or `bower_components/` (they are in `.gitignore`). Cloners run **`npm run docker:up`** (or the entrypoint fills volumes on first run).

---

## Git and GitHub (`git://` vs `https://`)

`npm` and Bower may fetch from Git. If installs fail with `git://` timeouts, configure Git once:

```bash
git config --global url."https://github.com/".insteadOf "git://github.com/"
```

The Docker image sets this in the Dockerfile; the entrypoint sets it again at runtime when possible.

---

## Manual `docker run` (without Compose)

After `npm run docker:build`:

```bash
docker run --rm -p 9000:9000 -p 35729:35729 \
  -v tcamt_prm_client_node_modules:/app/node_modules \
  -v tcamt_prm_client_bower:/app/bower_components \
  tcamt-prm/tcamt-client:dev
```

(`npm run docker:run` is the same idea with fixed volume names.)

---

## Local development without Docker

Use **Node 13.12.0** and **npm 6.14.4** (e.g. [nvm](https://github.com/nvm-sh/nvm): `nvm install 13.12.0 && nvm use` — `.nvmrc` pins this).

```bash
npm install
bower install   # or: node node_modules/bower/bin/bower install --allow-root
npx grunt serve
```

- Dev server: **http://localhost:9000** (Grunt task name is **`serve`**, not `server`).
- SCSS is compiled with **Dart Sass** (`sass` npm package) via Grunt, not Ruby Compass (see `Gruntfile.js`).

Production-style assets:

```bash
npx grunt build
```

Output is configured to go under the Java webapp (`tcamt-lite-controller/src/main/webapp`) for the full stack build.

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| **Port already in use** | Stop other containers or change the host port in `docker-compose.yml` (`"9001:9000"`). |
| **Empty / broken UI after clone** | Run `npm run docker:clean-volumes` then `npm run docker:up` so `npm` + `bower` run again. |
| **Native module build errors on host** | Install Python 3 + build tools (`build-essential` / Xcode CLI) or use Docker. |
| **`primordials is not defined` (Grunt)** | Known with some old plugins on newer Node; **Node 13** matches this project. |
| **`fsevents` optional install failed** | Often safe to ignore on Linux containers; optional dependency for watch. |

---

## Relation to the parent repository

- **`tcamt-lite-client/`** — this frontend; Docker files here are for **Grunt dev / build**.
- **Repository root `Dockerfile`** — builds a **Tomcat** image that deploys the **Java WAR** (`tcamt-lite-controller`). That is separate from the client dev Docker setup.

Use **`./build.sh -v <image-tag> [-l]`** at the repo root for the full Maven + multi-arch Docker image pipeline when you need the backend WAR (no separate `hit-resource-client` checkout).

---

## Legacy note

Older instructions in `README.txt` referred to `grunt server` and Compass. The current Grunt task is **`grunt serve`**, and styles use **Dart Sass** (`sass` npm package) via Grunt.
