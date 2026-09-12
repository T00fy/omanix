#!/bin/bash

# Toggle bar visibility without killing the Omanix shell.
# Usage: omanix-toggle-bar [toggle|on|off]  (default: toggle)

set -euo pipefail

# HOME-based to match the directory the shell watches (see lib/state.nix).
state_dir="$HOME/.local/state/omanix/toggles"
flag="$state_dir/bar-off"
mkdir -p "$state_dir"

case "${1:-toggle}" in
  on)     rm -f "$flag" ;;
  off)    : >"$flag" ;;
  toggle) if [[ -e $flag ]]; then rm -f "$flag"; else : >"$flag"; fi ;;
  *)      echo "usage: ${0##*/} [toggle|on|off]" >&2; exit 1 ;;
esac

# The shell's watch on the toggles directory can miss flag changes that land in
# quick succession, stranding the bar off screen until the shell restarts.
# Nudge the bar to re-read the flag; quiet best-effort so the toggle still
# works when the shell is not up.
omanix-shell -q omanix.bar syncHidden
