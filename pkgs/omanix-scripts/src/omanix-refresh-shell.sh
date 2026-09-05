#!/bin/bash

# Re-apply the declarative base over ~/.config/omanix/shell.json and reload the
# shell. This is the manual trigger of the activation-time reconcile: declared
# keys (from the Nix-generated base) win, runtime-only keys are preserved.
#
# The merge here MUST stay in sync with home.activation.omanixShellConfig in
# modules/home-manager/desktop/quickshell.nix (same declared base, same
# `jq -s '.[0] * .[1]'`). Succeeds whether or not the shell is running.

set -euo pipefail

base="${OMANIX_SHELL_DEFAULTS:-}"
[[ -n $base && -f $base ]] || { echo "omanix-refresh-shell: no declared shell base available" >&2; exit 1; }

config_dir="$HOME/.config/omanix"
config_file="$config_dir/shell.json"
mkdir -p "$config_dir"

tmp="$config_file.tmp"
if [[ -f $config_file ]] && jq -e . "$config_file" >/dev/null 2>&1; then
  jq -s '.[0] * .[1]' "$config_file" "$base" >"$tmp"
else
  cp "$base" "$tmp"
fi
mv "$tmp" "$config_file"
chmod u+w "$config_file"

# Best-effort reload; never fail if the shell is down.
if ! omanix-shell shell reloadConfig >/dev/null 2>&1; then
  omanix-shell -q shell rescanPlugins >/dev/null 2>&1 || true
fi
