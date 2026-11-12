#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mkdir -p workspace backups
if [[ ! -f .env ]]; then
  cp .env.example .env
  chmod 600 .env
  uid="$(id -u)"
  gid="$(id -g)"
  if [[ "$uid" == "0" || "$gid" == "0" ]]; then
    printf 'Warning: host user is root; using default image UID/GID 1000.\n' >&2
  else
    sed -i.bak "s/^DEV_UID=.*/DEV_UID=${uid}/;s/^DEV_GID=.*/DEV_GID=${gid}/" .env
    rm -f .env.bak
  fi
  password="$(od -An -tx1 -N 32 /dev/urandom | tr -d ' \n')"
  if [[ "${#password}" != 64 ]]; then
    printf 'Failed to generate a secure password.\n' >&2
    exit 1
  fi
  sed -i.bak "s/^OPENCODE_PASSWORD=.*/OPENCODE_PASSWORD=${password}/" .env
  rm -f .env.bak
  printf 'Created .env (mode 600) with random OPENCODE_PASSWORD.\n'
else
  printf 'Existing .env preserved without changes.\n'
fi
printf 'Workspace: %s/workspace (change WORKSPACE_DIR in .env as needed).\n' "$PWD"
printf 'Local URL: http://127.0.0.1:4095 (run make up).\n'
