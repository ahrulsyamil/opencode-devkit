# Contributing

Thanks for considering a contribution to OpenCode DevKit. This is an independent, volunteer-maintained open-source project.

1. Open an issue before making a large architectural change.
2. Fork and branch from `main` (for example, `feat/add-deno-profile`).
3. Keep changes small and focused. Add a test or CI check for any new tool or persistent mount.
4. Run `make verify`, `bash -n scripts/*.sh`, and where possible `make up && make smoke && make test-persistence`.
5. Document OS/CPU support and the security impact of any added binaries or privileges.
6. Submit a pull request using the template. Don't include `.env`, private keys, provider tokens, or personal workspace files.

Prefer pinned dependencies and official sources; avoid adding new privileged mounts or arbitrary download-and-execute scripts. All code contributions are submitted under the MIT license.
