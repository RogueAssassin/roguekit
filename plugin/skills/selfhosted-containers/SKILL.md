---
name: selfhosted-containers
description: Use for self-hosted Docker or Podman services: Compose files, Dockerfile/Containerfile, install.sh and update.sh scripts, image updates, health checks, volumes, networking, and Python container apps (dashboards, validators, ops consoles).
---
# Self-hosted containers (Docker and Podman)

Applies to small Python (or Node) services shipped as `Dockerfile`/`Containerfile` + `compose.yaml` + `install.sh`/`update.sh` + `VERSION` + `CHANGELOG.md`.

## Before changing anything
- Identify the runtime (Docker or Podman, rootless or rootful), Compose flavour (`docker compose` vs `podman compose`/`podman-compose`), base image and Python/Node version from the repo files, not assumptions.
- Read `compose.yaml`, the image file, `.env.example`, `install.sh`/`update.sh` and `SECURITY.md` first.

## Image and Compose rules
- Pin base images by version tag (digest for release builds); slim/alpine variants only if native wheels allow it. Multi-stage builds; run as a **non-root user**; `.dockerignore`/`.containerignore` kept in sync.
- Compose: `restart: unless-stopped`, a real `healthcheck`, resource limits where sensible, named volumes for data, read-only root filesystem and `cap_drop: [ALL]`/`no-new-privileges` when the app allows it. Keep Docker/Podman-compatible syntax unless the repo targets one engine.
- **Never mount the engine socket** (`/var/run/docker.sock`, Podman socket) into a service unless that is the explicit, documented purpose of the tool, and then restrict it (read-only, socket proxy, auth in front). Bind admin UIs to `127.0.0.1` behind a reverse proxy.
- Config through environment variables and mounted files. Ship `.env.example` with safe placeholders; the real `.env` is git-ignored. No secrets in images, compose files, logs or commits.
- Podman specifics: SELinux volume labels (`:Z`/`:z`), rootless user namespaces and UID mapping, `systemd`/Quadlet units for boot start, no daemon.

## Scripts (`install.sh`, `update.sh`)
- `set -euo pipefail`, quote variables, LF line endings (set in `.gitattributes`), no `curl | sh` of unverified content, idempotent re-runs.
- **Updates**: pull or build the new image, **verify** it (digest/signature/checksum or health check), keep the previous image tagged for rollback, back up volumes first, restart, check health, roll back automatically on failure. Never delete data volumes in an update path.
- Print what will change and support a dry-run/`--check` mode.

## Application side
- Health endpoint (`/health`) that does not leak internals; structured logs to stdout; graceful shutdown on SIGTERM; bounded memory and queue sizes.
- Persist state in a mounted path (SQLite WAL mode is fine for single-writer); migrations run at startup and are tested on a copy.
- Auth on every admin/API route, CSRF/origin checks for browser UIs, rate limiting on login, input validation, no shell-outs with user input.
- Python: pin dependencies (`pyproject.toml`/lock), `pytest` for logic, `python -m compileall`, type hints on public functions.

## Verify
`docker compose config` (or `podman compose config`) for syntax, build the image, run tests inside or beside it, start it, check the health endpoint and logs, then test update and rollback on a scratch copy. Say which of these you could not run (often there is no engine on the Windows dev box). Never run against a production host without approval.

See the `linux-server-admin` skill for host-level work and `python-development` for code quality.
