# syntax=docker/dockerfile:1.7
# The official OpenCode image is Alpine/musl as of OpenCode 2.4.2.
ARG OPENCODE_VERSION=2.4.2
FROM ghcr.io/anomalyco/opencode:${OPENCODE_VERSION} AS core

ARG DEV_UID=1000
ARG DEV_GID=1000
ARG PNPM_VERSION=10.34.9
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
    RTK_DISABLED=1 \
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

# RTK OSS release assets and matching upstream OpenCode plugin. Keep the
# version and all three checksums in sync when upgrading.
ARG TARGETARCH
RUN set -eux; \
  rtk_version=v1.2.1; \
  case "$TARGETARCH" in \
    amd64) rtk_arch=x86_64; rtk_sha=44aa460c4827d206d11405c652832c9f7082edccfbc3a9f15a69a851e8a9e8b4 ;; \
    arm64) rtk_arch=aarch64; rtk_sha=b01860ae2d3f44e0f7fc4431a95dd66b29b4bd87ec7f5e60aff13681b05db5dd ;; \
    *) echo "Unsupported RTK architecture: $TARGETARCH" >&2; exit 1 ;; \
  esac; \
  tmp_dir="$(mktemp -d)"; \
  asset="rtk-oss-${rtk_arch}-unknown-linux-musl.tar.gz"; \
  plugin_sha=f1b1a99842616e824c30612cc37c67e4b75d38f2346accbe79c240cf4bc31368; \
  curl -fsSL --retry 3 -o "$tmp_dir/$asset" "https://github.com/rtk-ai/rtk/releases/download/${rtk_version}/${asset}"; \
  curl -fsSL --retry 3 -o "$tmp_dir/rtk.ts" "https://raw.githubusercontent.com/rtk-ai/rtk/${rtk_version}/hooks/opencode/rtk.ts"; \
  printf '%s  %s\n' "$rtk_sha" "$tmp_dir/$asset" "$plugin_sha" "$tmp_dir/rtk.ts" > "$tmp_dir/checksums"; \
  sha256sum -c "$tmp_dir/checksums"; \
  tar -xzf "$tmp_dir/$asset" -C "$tmp_dir" rtk LICENSE; \
  install -m 0755 "$tmp_dir/rtk" /usr/local/bin/rtk; \
  install -Dm 0644 "$tmp_dir/LICENSE" /usr/local/share/licenses/rtk/LICENSE; \
  install -Dm 0644 "$tmp_dir/rtk.ts" /etc/opencode/plugins/rtk.ts; \
  rtk --version; \
  rm -rf "$tmp_dir"

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
