#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

marker="devkit-persistence-$(date +%s)-$$"
# Seed config, data, and workspace with unique markers, then force recreate.
docker compose exec -T -e "PERSIST_MARKER=$marker" opencode sh -ec '
  printf "%s" "$PERSIST_MARKER" > "$HOME/.local/share/opencode/.devkit-recreate-test"
  printf "%s" "$PERSIST_MARKER" > "$HOME/.config/.devkit-recreate-test"
  printf "%s" "$PERSIST_MARKER" > /workspace/.devkit-recreate-test
'
docker compose up -d --wait --force-recreate --no-deps opencode

docker compose exec -T -e "PERSIST_MARKER=$marker" opencode sh -ec '
  test "$(cat "$HOME/.local/share/opencode/.devkit-recreate-test")" = "$PERSIST_MARKER"
  test "$(cat "$HOME/.config/.devkit-recreate-test")" = "$PERSIST_MARKER"
  test "$(cat /workspace/.devkit-recreate-test)" = "$PERSIST_MARKER"
  rm -f "$HOME/.local/share/opencode/.devkit-recreate-test" \
        "$HOME/.config/.devkit-recreate-test" /workspace/.devkit-recreate-test
'
printf 'PASS: config, data and workspace survived force-recreate.\n'
