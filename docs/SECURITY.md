# Security and threat model

## Defaults

- OpenCode executes shell commands and modifies files in `/workspace`. Treat prompts, repositories, scripts, model output, and downloaded code as untrusted; inspect changes before applying to important projects.
- Server port is published to **host loopback only** (`127.0.0.1:4095`) on Docker bridge. It is not internet-ready. Use an SSH tunnel for VPS access.
- `OPENCODE_PASSWORD` is required by Compose, generated locally, and ignored by git. Use HTTPS in front of any non-loopback deployment; Basic Auth over HTTP is not enough on a network.
- The container runs as `devkit` (non-root) with dropped Linux capabilities and `no-new-privileges`; it has no Docker socket and no `privileged` flag. These controls mitigate but do not eliminate malicious agent execution.
- No SSH keys, personal home directories, or GitHub tokens are mounted by default.
- Dependency update versions are pinned for OpenCode, pnpm and agent-browser. Alpine package versions should be pinned via repository snapshot for strict reproducibility.
- GitHub Actions use scoped permissions; workflow publishing requests `packages: write` only for a tag release.

## Security checklist

- [ ] `.env` exists, is `0600`, and is never committed.
- [ ] The bind address remains `127.0.0.1` unless a reverse proxy and access control are in place.
- [ ] Password is rotated if exposed; regenerate and restart. Past browser sessions may need reauthentication.
- [ ] Only trusted project paths are mounted; avoid host root and sensitive directories.
- [ ] Host backups are encrypted and access-controlled; OpenCode SQLite can contain provider tokens.
- [ ] Container runs non-root; no Docker socket, `privileged`, host networking, or broad host capabilities.
- [ ] Images are built from verified official sources and scanned for vulnerabilities.
- [ ] Workflow actions and dependencies are reviewed and version pinned/digest pinned for releases.
- [ ] If browser sandboxing fails, investigate the host environment rather than silently disabling sandbox protections.
- [ ] `docker compose down -v` and destructive prune commands are not used unintentionally.

## Docker CLI risks

The `full` profile installs **only** Docker client binaries. Mounting `/var/run/docker.sock` would grant the container power to control the host daemon and is often effectively host-root. This example does not mount it. For remote builds, use a dedicated remote builder with scoped credentials and isolation.

## Browser sandbox trade-off

Chromium requires Linux namespace/seccomp capabilities. A non-root container with `cap_drop: ALL`, `no-new-privileges` and default seccomp may not launch Chromium with its full sandbox on all Docker hosts. Agent-browser may choose Docker-specific launch flags depending on upstream behavior; verify actual launch args and isolation before using untrusted sites. Prefer an isolated browser worker or stronger VM boundary for adversarial content. Avoid using `--no-sandbox` on shared hosts unless documented, risk-accepted, and otherwise isolated.

## Secrets and supply chain

Provider credentials saved through OpenCode can be stored in SQLite, inside the persisted data volume. Environment variables are visible to Docker administrators. Keep your VPS patched and Docker daemon access restricted. Prefer trusted registries; audit new scripts; do not curl-pipe shell scripts by default.

For publishing: create release tags only after review, CI, and an image scanner pass. Cross-architecture build success alone does not prove runtime feature parity.
