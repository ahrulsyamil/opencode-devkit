#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ $# != 1 ]]; then
  echo "Usage: scripts/restore.sh backups/devkit-YYYYMMDDTHHMMSSZ.tar.gz" >&2
  exit 2
fi
file="$(realpath -- "$1")"
[[ -f "$file" ]] || { echo "Backup not found: $file" >&2; exit 1; }
# Reject absolute paths, traversal paths, symlinks and special file entries.
if ! tar -tzf "$file" | awk '
  /^\// || /(^|\/)\.\.($|\/)/ { bad=1 }
  END { exit bad ? 1 : 0 }
'; then
  echo 'Unsafe archive paths detected.' >&2
  exit 1
fi
if tar -tvzf "$file" | awk 'substr($1,1,1) != "-" && substr($1,1,1) != "d" { bad=1 } END { exit bad ? 1 : 0 }'; then
  :
else
  echo 'Refusing archive containing symlinks or special entries.' >&2
  exit 1
fi
printf 'This replaces files in the six persistent volumes. Service will be stopped.\n'
printf 'Type RESTORE to continue: '
read -r confirm
[[ "$confirm" == 'RESTORE' ]] || { echo 'Cancelled.'; exit 1; }
docker compose stop opencode
# Only an archive created by this project should be restored.
docker compose run --rm --no-deps -v "$(dirname "$file"):/backup:ro" \
  --entrypoint sh opencode -ec 'tar -xzf "/backup/$1" -C /home/devkit' \
  sh "$(basename "$file")"
printf 'Restore complete. Run make up. Workspace and .env restore separately.\n'
