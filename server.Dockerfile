# Build context: the umbrella folder (needs both syncloom-core and syncloom-server).
#   docker build -f syncloom-deploy/server.Dockerfile -t syncloom-server .
FROM rust:1-bookworm AS build
WORKDIR /src
COPY syncloom-core syncloom-core
COPY syncloom-server syncloom-server
WORKDIR /src/syncloom-server
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/syncloom-server/target \
    cargo build --release && cp target/release/syncloom-server /syncloom-server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --home-dir /data syncloom && mkdir -p /data/blobs && chown -R syncloom /data
COPY --from=build /syncloom-server /usr/local/bin/syncloom-server
USER syncloom
ENV LISTEN_ADDR=0.0.0.0:8080 BLOB_PATH=/data/blobs RUST_LOG=info,sqlx=warn
VOLUME /data
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s CMD ["syncloom-server", "healthcheck"]
ENTRYPOINT ["syncloom-server"]
