# Syncloom web app

The browser app of [Syncloom](https://github.com/Syncloom), a self-hosted, end-to-end encrypted file sync and key/value store. Files are encrypted in the browser with a WebAssembly build of the shared core.

Status: **public preview (0.x)**.

A static single-page app served by nginx on port `80`. It talks to the Syncloom server through the same host name, so run it with the Compose bundle in [syncloom-deploy](https://github.com/Syncloom/syncloom-deploy).

- Tags: `X.Y.Z` for each release, `latest` for the newest stable one, `beta-latest` for pre-releases
- Architectures: `linux/amd64`, `linux/arm64`

Source: <https://github.com/Syncloom/syncloom-web> · License: Apache-2.0
