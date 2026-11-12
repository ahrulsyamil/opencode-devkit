# Upgrading OpenCode and developer tools

1. Read the upstream OpenCode and agent-browser release notes and check the base-image Dockerfile/Alpine branch.
2. Back up persistent volumes (`make backup`) and the host workspace and `.env` separately.
3. Set a pinned version in `.env`, or use `make update-opencode VERSION=x.y.z` / `make update-tools PNPM=x.y.z AGENT_BROWSER=x.y.z`.
4. Rebuild and restart with `make up`.
5. Run `make smoke` and `make test-persistence`; for browser profiles, test a real browser launch on the target architecture.
6. If a version is incompatible, restore the prior image version in `.env` and rebuild. Database migrations may not be backward-compatible: retain a pre-upgrade backup.

`make update-tools` only changes pinned tool versions and rebuilds; it does not install arbitrary commands manually into the running container. `apk` packages follow the upstream Alpine package repositories tied to the official base image and are not exact package-version pins.

## Versioning and releases

- Follow SemVer for the DevKit project, independent of the OpenCode upstream version.
- Use `vMAJOR.MINOR.PATCH` tags for CI-driven GHCR publishing.
- Document breaking changes in the README or a changelog before release.
- Support the most recent tested OpenCode image and explicitly document the compatibility range.
- Check Renovate/Dependabot proposals manually; automation is review-only, not auto-merge.
