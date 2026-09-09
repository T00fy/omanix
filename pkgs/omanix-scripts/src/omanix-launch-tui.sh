#!/usr/bin/env bash

# Optional leading --app-id=<class> pins the window class verbatim (used by
# omanix-agent for the fixed org.omanix.agent id so window rules/themes target
# every agent window). Without it the class is derived from the command name.
CLASS=""
if [[ ${1:-} == --app-id=* ]]; then
  CLASS="${1#--app-id=}"
  shift
fi

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-tui [--app-id=<class>] [command] [args...]"
  exit 1
fi

# We use the 'org.omanix.[command]' class format to trigger
# the 'floating-window' rule defined in modules/home-manager/desktop/hyprland/rules.nix
[[ -n $CLASS ]] || CLASS="org.omanix.$(basename "$1")"

exec setsid omanix-term --class="$CLASS" -- "$@"
