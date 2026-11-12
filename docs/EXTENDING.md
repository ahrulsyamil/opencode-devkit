# Adding custom developer tools

Prefer **declarative image builds** over installing packages manually in running containers. The repository is meant to be forked without modifying its core files.

## Simple extension

Build a base image from the `browser` target and add your own packages:

```bash
docker build --target browser --build-arg OPENCODE_VERSION=2.2.7 \
  -t opencode-devkit-base:browser .
docker build -f examples/Dockerfile.custom -t my-opencode-devkit:latest .
```

Example `examples/Dockerfile.custom` uses `FROM opencode-devkit-base:browser`, switches to root only during installation, then drops back to `devkit`. It installs `shellcheck` as a reproducible example. Adjust it to add Bun, Deno or a language manager from a verified source with a pinned version and checksum.

To use the custom image, **do not** run the default Compose build; it would rebuild/retag the core image. Make a local override:

```yaml
# compose.custom.yaml (not committed)
services:
  opencode:
    image: my-opencode-devkit:latest
    build: !reset null
```

Then run `docker compose -f compose.yaml -f compose.custom.yaml up -d`. `!reset` requires a modern Docker Compose v2; if not supported, create a standalone Compose file without `build:`. The normal `make up` command is intended for the supplied Dockerfile profiles, not custom overrides.

## New profiles

For a commonly used tool group, add a Dockerfile stage:

```dockerfile
FROM core AS data-science
RUN apk add --no-cache python3 py3-pip ...
USER devkit
ENTRYPOINT ["/usr/local/bin/devkit-entrypoint"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "4095"]
```

Then set `DEVKIT_PROFILE=data-science`. For a stable open-source contribution, document all Alpine package names, supported architectures, smoke commands, and a reason the tool belongs in that profile.

## Size and cache guidance

- Keep browsers and large compilers out of the `minimal` image.
- Keep npm/JS dependencies at project level and pin them with lockfiles in `/workspace`.
- Use Docker BuildKit layer caching and avoid invalidating core layers when adding optional packages.
- Clean only known package caches with `make clean-cache`; never delete OpenCode SQLite data.
- Do not add the Docker socket as a shortcut to host-side build tools.
