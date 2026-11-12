# Troubleshooting

| Symptom | Check / fix |
| --- | --- |
| `OPENCODE_PASSWORD` missing | Run `make init`; verify `.env` exists and is not blank. |
| Container unhealthy | `make logs`, `make doctor`; verify OpenCode is responding on internal port `4095`. |
| Port 4095 already taken | Change `OPENCODE_PORT` in `.env`, then `make up`; preserve `OPENCODE_BIND=127.0.0.1`. |
| `Permission denied` on workspace | Align `DEV_UID`/`DEV_GID` with host directory ownership, then rebuild; avoid `chmod 777`. |
| Credentials disappear | Ensure the same Compose project and `devkit-data` named volume remain. Check `opencode debug paths db`. |
| OpenCode config not updated from repo | First-run seed is intentionally non-destructive. Edit persisted `~/.config/opencode/opencode.json`. |
| `agent-browser` not found | Choose `DEVKIT_PROFILE=browser` or `full`; rebuild and use `make smoke`. |
| Chromium fails to launch | Check `agent-browser doctor`, executable `/usr/bin/chromium`, architecture, Docker namespaces/seccomp and container privileges. Do not automatically disable sandbox. |
| `pnpm` missing after rebuild | Check build cache/logs; `pnpm` is pinned in `Dockerfile` in every profile. |
| SSH fails to read key | Opt in to the example SSH override; ensure host UID/GID and `0600` key permissions. |
| Docker socket unavailable | By design: Docker CLI is included only in `full`, with no mounted host socket. |
| Tool installed manually disappears | Add it declaratively to a custom Dockerfile or target and rebuild. |

## Debugging

```bash
make doctor
make logs
make shell
opencode --version
opencode debug paths db
cat /etc/os-release
command -v node pnpm git agent-browser chromium
```

If your Docker/Compose host does not support the selected platform or Alpine packages, switch profiles or build a custom extension with a verified toolchain and document the limitation.
