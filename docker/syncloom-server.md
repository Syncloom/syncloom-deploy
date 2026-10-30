# Syncloom server

The server of [Syncloom](https://github.com/Syncloom), a self-hosted, end-to-end encrypted file sync and key/value store. It stores only ciphertext. Accounts require a second factor (authenticator app or security key), and OpenID Connect is supported.

Status: **public preview (0.x)**.

This image needs Postgres and is meant to run behind the Compose bundle in [syncloom-deploy](https://github.com/Syncloom/syncloom-deploy), which also adds HTTPS (Caddy) and the web app.

- Listens on `8080` (`LISTEN_ADDR`), data in `/data` (`BLOB_PATH=/data/blobs`)
- Runs as a non-root user; `syncloom-server healthcheck` is the health check
- Tags: `X.Y.Z` for each release, `latest` for the newest stable one, `beta-latest` for pre-releases
- Architectures: `linux/amd64`, `linux/arm64`

Source: <https://github.com/Syncloom/syncloom-server> · License: Apache-2.0
