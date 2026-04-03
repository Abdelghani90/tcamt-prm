# TCAMT deploy (Docker Compose)

Full stack: **MongoDB**, **MySQL**, **Tomcat WAR** (`tcamt-prm/tcamt-webapp`), and **Angular Grunt dev server** (`tcamt-client`).

## Prerequisites

- Docker with Compose v2
- `tcamt-prm/tcamt-webapp:latest` available locally or from a registry (build with repo `build.sh` if needed)
- `context.xml` beside this file (Tomcat datasource / JNDI)
- `mysql-init` SQL (e.g. `init.sql`) for first-time DB init

Compose services: **`tcamt-webapp`**, **`tcamt-mongo`**, **`tcamt-mysql`**. Tomcat logs on the host: **`logs/tcamt-webapp/`**. If you previously used **`logs/hl7v2-tcamt/`**, copy or symlink into the new path, or remove the old folder and let Compose create the new one.

## Run everything

From the **`tcamt-deploy`** directory:

```bash
docker compose up --build
```

Then:

| Service | URL / port |
|--------|----------------|
| **Frontend (Grunt)** | **http://localhost:9000** — use this for development; API calls are proxied to Tomcat. |
| Tomcat (WAR) | http://localhost:8096/tcamt/ (direct backend) |
| MySQL | `localhost:3379` (from host) |

The frontend container (`tcamt-client`) sets **`TCAMT_BACKEND_URL=http://tcamt-webapp:8080`** so Grunt forwards ` /api/*` and `/j_spring*` to the Tomcat app context **`/tcamt`**.

## Backend-only (no frontend container)

Comment out or remove the **`tcamt-client`** service in `docker-compose.yml`, then run `docker compose up --build` as usual.

## Frontend volumes

`bower_components` and `node_modules` are **gitignored** in the repo; Compose uses named volumes (`tcamt_client_*`) so the first run runs `npm install` / `bower install` via the image entrypoint. To force a clean reinstall:

```bash
docker compose down -v
docker compose up --build
```

## Paths

- `../tcamt-lite-client` — build context for the **tcamt-client** image (Dockerfile in that folder).
- Adjust `build.context` if you move `tcamt-deploy` relative to the repo.

## Related

- Root **`build.sh`** — Maven + multi-arch image for `tcamt-prm/tcamt-webapp`.
- **`tcamt-lite-client/README.md`** — local Node / Grunt without Compose.
