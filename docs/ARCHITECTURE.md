# Architecture and persistence

## Decisions

1. **Official Alpine image**: use `ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}` as a base. The current upstream `packages/cli/Dockerfile` uses Alpine and `apk`. Check the upstream Dockerfile when upgrading; do not assume the distribution will never change.
2. **Immutable OS/tool layer**: every supported tool is added by a Dockerfile build target and installed from Alpine repositories or version-pinned npm packages. `docker compose up -d --force-recreate` retains these tools because they live in the rebuilt image, not the container writable layer.
3. **Build-time profiles**: one small core; `web`, `browser`, `full` extend it without installing every heavy tool by default.
4. **Non-root process**: `devkit` uses configured UID/GID and does not require host Docker socket or privileged mode. Default container capabilities are dropped.
5. **Bridge port publishing**: host bind address is `127.0.0.1`; `0.0.0.0` inside container is needed for Docker port forwarding. Public access requires a separate TLS/auth architecture.
6. **Persistent XDG paths**: config/data/state/cache live in independently mounted named volumes; workspace is host-owned and bind-mounted.

## Image versus volume versus host

| Image, recreated on rebuild | Persistent volumes | Host bind mount | Ephemeral |
| --- | --- | --- | --- |
| OpenCode binary, OS tools, Node/npm/pnpm, browser executable, optional toolchains | Config, auth/session SQLite DB, app state, npm/pnpm caches, browser profile | Workspace/projects (default `./workspace`) | `/tmp`, manually installed tools in writable layer, unsaved shell state |

OpenCode v2 normally stores its database under `~/.local/share/opencode/opencode.db`. `XDG_DATA_HOME` points to `/home/devkit/.local/share`, which is persisted. `XDG_CONFIG_HOME` points to persisted `/home/devkit/.config`. The absolute OpenCode database path can be checked using `opencode debug paths db` inside the container.

`.env` is stored **outside** Docker volumes and must be protected and backed up independently. Host SSH keys are never included automatically. Git user configuration persists in `/home/devkit/.config/git/config` using the `GIT_CONFIG_GLOBAL` environment variable. Browser settings are under `~/.agent-browser`; browser caches may also use `~/.cache`.

## Force recreation

```
make init
make up
make test-persistence
```

The test creates separate markers in config, data, and `/workspace`, runs `docker compose up -d --force-recreate`, verifies every marker, then removes them. It is not a substitute for full application-level restore testing or a live DB-consistency test.

Retained when volumes and workspace directory survive: `docker compose down`, image rebuild, force recreation, normal service replacement. Deleted when: `docker compose down -v`, explicit volume deletion, deleting/moving the host workspace, destructive restore, disk failure or a changed Compose project name without migration.

## Versioning / reproducibility

`OPENCODE_VERSION`, `PNPM_VERSION` and `AGENT_BROWSER_VERSION` are pinned in `.env`/Docker build args. Alpine package indices change over time, so package versions and base-image tag are **not** completely bit-for-bit reproducible. For strict production reproducibility, pin the base image digest and use stable APK repository snapshots, then scan and rebuild deliberately.
