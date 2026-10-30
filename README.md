# syncloom-deploy

Docker Compose bundle: Caddy (automatic HTTPS), the server, the web app and Postgres, with a blob volume or any S3-compatible store.

Part of [Syncloom](https://github.com/Syncloom), a self-hosted, end-to-end encrypted file sync and key/value store. Status: **public preview (0.1)**.

```bash
git clone https://github.com/Syncloom/syncloom-deploy.git && cd syncloom-deploy
cp .env.example .env              # set SYNCLOOM_DOMAIN and POSTGRES_PASSWORD
docker compose up -d
```
Trial on your own machine over plain HTTP: `docker compose -f docker-compose.yml -f docker-compose.test.yml up -d`, then open <http://localhost:8088>. The images build from the sibling repositories (`../syncloom-server`, `../syncloom-web`, `../syncloom-core`).

## Working with the other repositories

The Syncloom repositories reference each other by relative path. Clone the ones you need **side by side in one folder**, for example `syncloom-core`, `syncloom-server` and `syncloom-web` next to each other.

## License

Apache License 2.0, see [LICENSE](LICENSE).
