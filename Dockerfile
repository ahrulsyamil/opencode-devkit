# syntax=docker/dockerfile:1.7
# The official OpenCode image is Alpine/musl as of OpenCode 2.2.7.
ARG OPENCODE_VERSION=2.2.7
FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION} AS core

ARG DEV_UID=1000
ARG DEV_GID=1000
ARG PNPM_VERSION=10.24.0
ENV HOME=/home/devkit \
    TZ=Asia/Jakarta \
    XDG_CONFIG_HOME=/home/devkit/.config \
    XDG_DATA_HOME=/home/devkit/.local/share \
    XDG_STATE_HOME=/home/devkit/.local/state \
    XDG_CACHE_HOME=/home/devkit/.cache \
    PNPM_HOME=/home/devkit/.local/share/pnpm \
    NPM_CONFIG_CACHE=/home/devkit/.npm \
    NPM_CONFIG_USERCONFIG=/home/devkit/.config/npm/npmrc \
    GIT_CONFIG_GLOBAL=/home/devkit/.config/git/config \
    HISTFILE=/home/devkit/.local/state/bash_history \
    PATH=/home/devkit/.local/share/pnpm:$PATH

# All core packages are part of immutable image layers, not container writable state.
RUN set -eux; \
    apk add --no-cache \
      bash ca-certificates tzdata curl wget git openssh-client \
      jq yq zip unzip tar gzip make build-base \
      ripgrep fd fzf tree less nano vim \
      findutils grep sed coreutils procps iproute2 bind-tools \
      nodejs npm; \
    npm install --global --no-audit --no-fund "pnpm@${PNPM_VERSION}"; \
    test "${DEV_UID}" -gt 0 && test "${DEV_GID}" -gt 0; \
    addgroup -g "${DEV_GID}" devkit; \
    adduser -D -h /home/devkit -s /bin/bash -u "${DEV_UID}" -G devkit devkit; \
    install -d -o devkit -g devkit \
      /home/devkit/.config/opencode \
      /home/devkit/.local/share/opencode \
      /home/devkit/.local/state/opencode \
      /home/devkit/.cache \
      /home/devkit/.npm \
      /home/devkit/.agent-browser \
      /workspace

COPY config/opencode.json /opt/devkit/defaults/opencode.json
COPY scripts/entrypoint.sh /usr/local/bin/devkit-entrypoint
COPY scripts/healthcheck.mjs /opt/devkit/healthcheck.mjs
RUN chmod 0755 /usr/local/bin/devkit-entrypoint \
    && chmod 0644 /opt/devkit/defaults/opencode.json /opt/devkit/healthcheck.mjs \
    && chown -R devkit:devkit /home/devkit /workspace

WORKDIR /workspace
EXPOSE 4095
HEALTHCHECK --interval=30s --timeout=7s --start-period=45s --retries=3 \
    CMD node /opt/devkit/healthcheck.mjs

# Core + Node/npm/pnpm. No Chromium or optional toolchain.
FROM core AS minimal
USER devkit
ENTRYPOINT ["/usr/local/bin/devkit-entrypoint"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4095"]

# Web/API workflow: Python+uv and database CLI tools, not browsers.
FROM core AS web
RUN apk add --no-cache python3 py3-pip uv \
    postgresql-client mariadb-client sqlite redis
USER devkit
ENTRYPOINT ["/usr/local/bin/devkit-entrypoint"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4095"]

# Browser workflow: native agent-browser supports Linux musl amd64/arm64.
# Alpine Chromium avoids downloading an unsupported Chrome-for-Testing ARM64 build.
FROM core AS browser-packages
ARG AGENT_BROWSER_VERSION=0.42.0
RUN set -eux; \
    apk add --no-cache chromium nss freetype harfbuzz ttf-freefont; \
    npm install --global --no-audit --no-fund "agent-browser@${AGENT_BROWSER_VERSION}"; \
    agent-browser --version; \
    chromium --version
ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium
FROM browser-packages AS browser
USER devkit
ENTRYPOINT ["/usr/local/bin/devkit-entrypoint"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4095"]

# Heavy development toolchains. Opt in with DEVKIT_PROFILE=full.
FROM browser-packages AS full
RUN apk add --no-cache \
      python3 py3-pip uv \
      go rust cargo openjdk21-jdk \
      docker-cli docker-cli-compose github-cli \
      postgresql-client mariadb-client sqlite redis
USER devkit
ENTRYPOINT ["/usr/local/bin/devkit-entrypoint"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4095"]
