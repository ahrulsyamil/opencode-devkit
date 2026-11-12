#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker compose exec -T opencode sh -ec '
  command -v opencode >/dev/null
  command -v git >/dev/null
  command -v node >/dev/null
  command -v npm >/dev/null
  command -v pnpm >/dev/null
  command -v jq >/dev/null
  command -v yq >/dev/null
  test -f "$HOME/.config/opencode/opencode.json"
  opencode --version
  git --version
  node --version
  npm --version
  pnpm --version
  if command -v agent-browser >/dev/null 2>&1; then
    agent-browser --version
    test -x "$AGENT_BROWSER_EXECUTABLE_PATH"
    "$AGENT_BROWSER_EXECUTABLE_PATH" --version
  fi
'
docker compose ps
printf '\nSmoke test complete. A healthy service is expected above.\n'
