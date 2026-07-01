# syntax=docker/dockerfile:1
ARG OPENCHAMBER_VERSION=v1.13.8

FROM alpine/git:2.45 AS source
ARG OPENCHAMBER_VERSION
RUN git clone --depth 1 --branch ${OPENCHAMBER_VERSION} \
    https://github.com/openchamber/openchamber.git /openchamber

FROM oven/bun:1 AS deps
WORKDIR /app
COPY --from=source /openchamber/package.json /openchamber/bun.lock ./
COPY --from=source /openchamber/packages/ui/package.json ./packages/ui/
COPY --from=source /openchamber/packages/web/package.json ./packages/web/
COPY --from=source /openchamber/packages/electron/package.json ./packages/electron/
COPY --from=source /openchamber/packages/vscode/package.json ./packages/vscode/
RUN bun install --frozen-lockfile --ignore-scripts

FROM oven/bun:1 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=source /openchamber .
RUN bun run build:web

FROM oven/bun:1 AS runtime
WORKDIR /home/openchamber

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    less \
    nodejs \
    npm \
    openssh-client \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN userdel bun \
    && groupadd -g 1000 openchamber \
    && useradd -u 1000 -g 1000 -m -s /bin/bash openchamber \
    && chown -R openchamber:openchamber /home/openchamber

USER openchamber

ENV NPM_CONFIG_PREFIX=/home/openchamber/.npm-global
ENV PATH=${NPM_CONFIG_PREFIX}/bin:${PATH}

RUN npm config set prefix /home/openchamber/.npm-global \
    && mkdir -p /home/openchamber/.npm-global \
    && mkdir -p /home/openchamber/.local /home/openchamber/.config /home/openchamber/.ssh \
    && npm install -g opencode-ai

ENV NODE_ENV=production

COPY --from=source /openchamber/scripts/docker-entrypoint.sh /home/openchamber/openchamber-entrypoint.sh

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/packages/web/package.json ./packages/web/package.json
COPY --from=builder /app/packages/web/bin ./packages/web/bin
COPY --from=builder /app/packages/web/server ./packages/web/server
COPY --from=builder /app/packages/web/dist ./packages/web/dist

EXPOSE 3000

ENTRYPOINT ["sh", "/home/openchamber/openchamber-entrypoint.sh"]
