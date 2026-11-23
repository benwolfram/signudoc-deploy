# SignuDoc (github.com/NYLLON-SOFTWARE/SignuDoc), built from an upstream
# release tag. Upstream ships no Dockerfile; this one is ours.
ARG SIGNUDOC_VERSION

FROM node:24-slim AS build
ARG SIGNUDOC_VERSION
RUN test -n "$SIGNUDOC_VERSION" \
 && apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY patches /patches
# Our changes on top of upstream, one concern per patch. A patch that no
# longer applies fails the build: rebase it before bumping VERSION.
RUN git clone --depth 1 --branch "$SIGNUDOC_VERSION" \
      https://github.com/NYLLON-SOFTWARE/SignuDoc.git . \
 && for p in /patches/*.patch; do git apply --verbose "$p"; done \
 && rm -rf .git
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm ci && npm run build && npm prune --omit=dev

FROM node:24-slim
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    STORAGE_LOCAL_DIR=/data/storage
WORKDIR /app
COPY --from=build --chown=node:node /app /app
RUN mkdir -p /data/storage && chown node:node /data/storage
USER node
EXPOSE 3000
# Migrations only apply what is new, so they run on every start.
CMD ["sh", "-c", "node db/migrate.mjs && exec node_modules/.bin/next start -H 0.0.0.0 -p 3000"]
