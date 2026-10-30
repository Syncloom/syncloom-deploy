# Build context: the umbrella folder.
#   docker build -f syncloom-deploy/web.Dockerfile -t syncloom-web .
FROM node:22-alpine AS build
WORKDIR /app
COPY syncloom-web/package.json syncloom-web/package-lock.json* ./
RUN npm install --no-audit --no-fund
COPY syncloom-web/ ./
# the WebAssembly bindings (src/lib/wasm) are committed; rebuild them with syncloom-web/build-wasm.sh
RUN npm run build

FROM nginx:1.27-alpine
COPY syncloom-deploy/nginx-web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
