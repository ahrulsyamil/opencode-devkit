#!/usr/bin/env bash
# Interactive maintainer helper. Never run automatically from CI or container entrypoint.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

repo='ahrulsyamil/opencode-devkit'
for name in git gh; do
  command -v "$name" >/dev/null || {
    echo "Missing $name. Install the GitHub CLI and run gh auth login first." >&2
    exit 1
  }
done
login="$(gh api user --jq .login)"
if [[ "$login" != 'ahrulsyamil' ]]; then
  echo "Authenticated GitHub user is $login; expected ahrulsyamil." >&2
  exit 1
fi
if gh repo view "$repo" >/dev/null 2>&1; then
  echo "Repository $repo already exists; refuse to overwrite or force-push." >&2
  echo "Use a normal git push after reviewing its branches/history." >&2
  exit 1
fi
if git remote get-url origin >/dev/null 2>&1; then
  echo 'An origin remote already exists; refuse to change existing repository.' >&2
  exit 1
fi
if [[ ! -d .git ]]; then
  git init -b main
fi
# Files listed in .gitignore, including .env and workspace contents, are excluded.
git add .
if git diff --cached --name-only | grep -E '(^|/)(\.env|id_rsa|id_ed25519|auth\.json)$|^workspace/[^.]' >/dev/null; then
  echo 'Potential secrets or workspace files staged. Review and unstage them.' >&2
  exit 1
fi
git status --short
printf '\nCreate a PUBLIC GitHub repository %s and push these files? Type PUBLISH: ' "$repo"
read -r confirmation
[[ "$confirmation" == PUBLISH ]] || { echo 'Cancelled.'; exit 1; }
if ! git diff --cached --quiet; then
  git commit -m 'Initial OpenCode DevKit open-source scaffold'
fi
gh repo create "$repo" --public --source=. --remote=origin --push
echo "Published: https://github.com/$repo"
