#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

for name in docker git; do
  command -v "$name" >/dev/null || { echo "Missing dependency: $name" >&2; exit 1; }
done
docker compose version
[[ -f .env ]] || { echo 'Missing .env: run make init' >&2; exit 1; }
[[ "$(stat -c %a .env 2>/dev/null || stat -f %Lp .env)" == "600" ]] || \
  echo 'Warning: prefer chmod 600 .env' >&2
docker compose config --quiet
docker compose ps
