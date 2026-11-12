#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p backups
backup_name="devkit-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
# Keep this archive private; the OpenCode database may contain tokens.
# Stop to avoid an inconsistent SQLite backup.
docker compose stop opencode
umask 077
HOST_BACKUPS="$(pwd)/backups"
docker compose run --rm --no-deps -v "${HOST_BACKUPS}:/backup" \
  --entrypoint sh opencode -ec \
  "tar -czf /backup/${backup_name} -C /home/devkit .config .local/share .local/state .cache .npm .agent-browser"
printf 'Backup saved: backups/%s\n' "$backup_name"
printf 'Workspace files and .env are NOT included. Back them up separately.\n'
