#!/bin/sh
set -eu

# The first start seeds a user-owned config into the persistent config volume.
# Never overwrite users' edits during image updates or force-recreate.
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
config_file="${config_dir}/opencode.json"
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/git" "${XDG_CONFIG_HOME:-$HOME/.config}/npm" "$config_dir" "${XDG_DATA_HOME:-$HOME/.local/share}/opencode" \
    "${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
if [ ! -e "$config_file" ]; then
  cp /opt/devkit/defaults/opencode.json "$config_file"
  chmod 0600 "$config_file"
fi

# Do not echo credentials. PID 1 handles signals via Docker init + exec.
exec opencode "$@"
