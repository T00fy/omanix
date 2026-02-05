#!/usr/bin/env bash

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-tui [command] [args...]"
  exit 1
fi

CMD_NAME=$(basename "$1")

# We use the 'org.omanix.[command]' class format to trigger
# the 'floating-window' rule defined in modules/home-manager/desktop/hyprland/rules.nix
exec setsid ghostty --class="org.omanix.$CMD_NAME" -e "$@"
