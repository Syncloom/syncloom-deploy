# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [semantic versioning](https://semver.org/). Syncloom is a public preview until 1.0.

## [Unreleased]

### Added
- `SYNCLOOM_HTTP_PORT` and `SYNCLOOM_HTTPS_PORT` choose the published ports (defaults 80 and 443), for hosts where those are taken. `SYNCLOOM_HTTPS_PORT` must match the port in `SYNCLOOM_DOMAIN` `SYNCLOOM_HTTP_BIND` restricts the HTTP port to one address..

## [0.1.1] - 2026-11-02

### Changed
- `docker compose up -d` now pulls the published images `svenwal/syncloom-server` and `svenwal/syncloom-web` from Docker Hub; a lone clone of this repository is enough. `SYNCLOOM_VERSION` selects the tag.
- Building from source moved to `docker-compose.build.yml` (add it as a second `-f`).

## [0.1.0] - 2026-11-02

First public preview.

### Added
- Docker Compose stack: Caddy (automatic TLS), server, web app, Postgres and a blob volume. Optional S3 storage.
- Test overlay for plain HTTP, smoke test and cross-client test scripts.
- GitHub Actions for Docker Hub images, triggered by `v*` tags.

### Known limits
- Compose builds the images from the sibling repositories instead of pulling published ones.
- A lone clone of this repository cannot build the images; clone the sibling repositories next to it.
