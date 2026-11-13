# Configuration reference

## `.env`

Create with `make init`. It generates a random 256-bit password from `/dev/urandom` and sets your local UID/GID. It never overwrites an existing `.env`.

| Variable | Default | Purpose |
| --- | --- | --- |
| `DEVKIT_PROFILE` | `browser` | Docker build target: minimal/web/browser/full |
| `DEVKIT_IMAGE` | `opencode-devkit:local` | Local image tag |
| `OPENCODE_VERSION` | `2.2.7` | Official OpenCode image tag |
| `PNPM_VERSION` | `10.34.9` | Globally installed pnpm npm version |
| `AGENT_BROWSER_VERSION` | `0.42.0` | Browser CLI npm version |
| `DEV_UID`, `DEV_GID` | local user, or `1000` | Image user/group ownership for bind mounts |
| `TZ` | `Asia/Jakarta` | Runtime timezone |
| `OPENCODE_BIND` | `127.0.0.1` | Host interface for published port |
| `OPENCODE_PORT` | `4095` | Host-visible TCP port |
| `WORKSPACE_DIR` | `./workspace` | Host path mounted at `/workspace` |
| `OPENCODE_CONFIG_DIR` | `devkit-opencode` | Named volume, or a `./`-relative/absolute host path bind-mounted at `/home/devkit/.config/opencode` |
| `OPENCODE_PASSWORD` | randomly generated | OpenCode HTTP Basic Auth password; never commit |

The server listens on **container port 4095**. Changing `OPENCODE_PORT` changes only the host port; the healthcheck still probes internal port 4095.

Keep `.env` mode `0600`. Avoid shell-expansion characters in manually written secrets because Compose applies variable substitution; let `make init` generate the password. `OPENCODE_PASSWORD` is passed as a container environment variable and can be viewed by anyone with Docker host administration privileges.

## OpenCode config

`config/opencode.json` is the first-start seed. It contains just:

```json
{"$schema": "https://opencode.ai/config.json", "update": "notify"}
```

On startup, the entrypoint writes this only when `~/.config/opencode/opencode.json` does not yet exist. Edit the persisted copy inside the running container:

```bash
make shell
nano ~/.config/opencode/opencode.json
```

If you want to replace it from a host file:

```bash
docker compose cp config/opencode.json opencode:/home/devkit/.config/opencode/opencode.json
```

This overwrites the persistent copy, so back it up first. The recommended path for project-specific OpenCode config is a `opencode.json(c)` file inside that project workspace.

## Git identity and SSH

The image sets `GIT_CONFIG_GLOBAL=/home/devkit/.config/git/config` so `git config --global` survives recreation. Configure identity using `make shell`:

```bash
mkdir -p ~/.config/git
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

SSH is **opt in**. Copy `examples/compose.ssh.yaml` locally and use it explicitly; file ownership/permissions must match the container runtime user. Never commit private keys or mount your whole home directory.

## Bind-mounting the OpenCode config

Only the OpenCode config directory (`/home/devkit/.config/opencode`) is switchable; Git/npm config stay in the `devkit-config` volume. Set `OPENCODE_CONFIG_DIR` in `.env` to a host path to switch from the nested `devkit-opencode` named volume to a bind mount (Compose treats sources starting with `./` or `/` as paths):

```bash
OPENCODE_CONFIG_DIR=./opencode-config
```

To migrate existing config out of a named volume first:

```bash
make down
mkdir -p opencode-config
docker run --rm -v opencode-devkit_devkit-opencode:/src:ro -v "$PWD/opencode-config:/dst" alpine cp -a /src/. /dst/
sudo chown -R "$(awk -F= '$1=="DEV_UID"{print $2}' .env):$(awk -F= '$1=="DEV_GID"{print $2}' .env)" opencode-config  # Linux only
make up
```

Config created before the nested volume existed lives in `devkit-config` instead; copy from `opencode-devkit_devkit-config:/src/opencode` in that case. On Linux the host directory must be writable by `DEV_UID`/`DEV_GID` (Docker creates missing bind paths as root). On macOS/Windows Docker Desktop usually handles this via file sharing. Check `docker volume ls` if unsure of the exact volume name. `make backup`/`make restore` keep working because they operate on container paths.

## Non-root UID/GID

Rebuild after changing `DEV_UID` or `DEV_GID`. Named volumes created using a previous UID might need an explicit one-time ownership migration. **Do not** use `chmod -R 777` as a workaround. Host paths need read/write permission for the matching UID/GID. macOS/Windows Docker Desktop uses filesystem virtualization and may behave differently from Linux.
