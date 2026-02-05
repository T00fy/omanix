#!/usr/bin/env bash

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-tui [command] [args...]"
  exit 1
fi

# Get the base name of the command (e.g., 'btop' from '/usr/bin/btop')
CMD_NAME=$(basename "$1")

# We use the 'org.omanix.[command]' class format to trigger 
# the 'floating-window' rule defined in modules/home-manager/desktop/hyprland/rules.nix
# We use 'uwsm app --' to ensure the app is registered correctly in the systemd session.
exec setsid uwsm app -- ghostty --class="org.omanix.$CMD_NAME" -e "$@"
