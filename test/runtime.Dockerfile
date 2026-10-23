ARG PACKAGE_STAGE=builder
FROM oven/bun:1.3.14 AS bun

FROM node:22-bookworm-slim AS builder
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
WORKDIR /checkout
COPY package.json bun.lock turbo.json ./
COPY apps/cli/package.json apps/cli/package.json
COPY packages/core/package.json packages/core/package.json
COPY packages/typescript-config packages/typescript-config
RUN bun install --frozen-lockfile
COPY apps/cli apps/cli
COPY packages/core packages/core
COPY scripts/build-cli.ts scripts/package-notices.mjs scripts/parser-assets.mjs scripts/
COPY scripts/licenses scripts/licenses
COPY LICENSE LICENSE
COPY skills skills
RUN bun run --cwd apps/cli build \
    && mkdir -p /artifacts \
    && npm pack ./apps/cli --pack-destination /artifacts \
    && mv /artifacts/*.tgz /artifacts/codecompass.tgz \
    && cp skills/codecompass/SKILL.md /artifacts/canonical-skill.md

FROM scratch AS prebuilt
COPY .package-input/codecompass.tgz /artifacts/codecompass.tgz
COPY .package-input/canonical-skill.md /artifacts/canonical-skill.md

FROM ${PACKAGE_STAGE} AS package

FROM node:22-bookworm-slim AS install
COPY --from=package /artifacts/codecompass.tgz /tmp/codecompass.tgz
RUN npm install --global --prefix /opt/codecompass --ignore-scripts --omit=dev /tmp/codecompass.tgz \
    && rm -rf /tmp/codecompass.tgz /root/.npm

FROM node:22-bookworm-slim AS runtime
COPY --from=install /opt/codecompass /opt/codecompass
COPY --from=package /artifacts/canonical-skill.md /test/canonical-skill.md
COPY test/installed.test.mjs /test/installed.test.mjs
COPY test/fixtures/provider-route.mjs /test/fixtures/provider-route.mjs
COPY --chmod=755 test/fixtures/skill-installer.mjs /test/fixtures/skill-installer.mjs
ENV PATH=/opt/codecompass/bin:/usr/local/bin:/usr/bin:/bin \
    CODECOMPASS_INSTALLED_BINARY=/opt/codecompass/bin/cc \
    CODECOMPASS_INSTALLED_PACKAGE=/opt/codecompass/lib/node_modules/@codecompass/cli \
    CODECOMPASS_EXPECTED_SKILL=/test/canonical-skill.md
USER node
WORKDIR /tmp
CMD ["node", "--test", "--test-concurrency=1", "/test/installed.test.mjs"]
