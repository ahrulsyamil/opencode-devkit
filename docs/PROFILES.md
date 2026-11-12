# Profiles

Choose `DEVKIT_PROFILE` in `.env` and run `make up`. Each name is an exact Dockerfile build target.

| Tool group | minimal | web | browser (default) | full |
| --- | :---: | :---: | :---: | :---: |
| OpenCode and core Unix utilities | ✓ | ✓ | ✓ | ✓ |
| Git, SSH client, curl/wget, jq/yq, rg/fd/fzf | ✓ | ✓ | ✓ | ✓ |
| Node.js, npm, pinned pnpm | ✓ | ✓ | ✓ | ✓ |
| Python, pip, uv | — | ✓ | — | ✓ |
| PostgreSQL, MariaDB/MySQL, Redis, SQLite CLIs | — | ✓ | — | ✓ |
| agent-browser native CLI | — | — | ✓ | ✓ |
| Alpine Chromium | — | — | ✓ | ✓ |
| Go, Rust/Cargo, Java JDK 21 | — | — | — | ✓ |
| Docker CLI/Compose, GitHub CLI | — | — | — | ✓ |

`minimal` is the small everyday JavaScript/TypeScript environment. `web` helps backend/database workflows; `browser` provides agent automation without the heavy backend toolchains; `full` is an opt-in catch-all. Runtime packages vary by Alpine base version. JavaScript and TypeScript project dependencies belong inside your project (in `/workspace`), not globally inside the image.

### Browser specifics

The upstream `agent-browser` npm package provides native Linux **musl** binaries for amd64 and arm64. `agent-browser@0.42.0` is pinned as a build argument; the installed command uses `/usr/bin/chromium` from Alpine, avoiding the Chrome-for-Testing Linux ARM64 download limitation. `AGENT_BROWSER_EXECUTABLE_PATH` selects that executable.

Running Chromium inside Docker may require sandbox features unavailable under certain host kernel/Docker seccomp settings. Do not blindly add `--no-sandbox`, `privileged: true`, `seccomp=unconfined`, or broad host capabilities. The CI browser launch job is intentionally a diagnostic test; if your host cannot launch it with the current hardened defaults, investigate namespaces or use a properly isolated remote browser.

### Optional toolchains not bundled by default

Bun, Deno, language version managers, extra database drivers, and uncommon CLI utilities are purposely left for custom Dockerfile extensions. This controls maintenance cost and image size. See [Extending](EXTENDING.md).
