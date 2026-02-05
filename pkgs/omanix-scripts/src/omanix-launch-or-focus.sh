#!/usr/bin/env bash

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-or-focus [window-pattern] [launch-command]"
  exit 1
fi

WINDOW_PATTERN="$1"
LAUNCH_COMMAND="${2:-"$WINDOW_PATTERN"}"

# 1. Query Hyprland for windows matching the class or title (case-insensitive)
WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" \
  '.[] | select((.class | test($p; "i")) or (.title | test($p; "i"))) | .address' | head -n1)

# 2. Focus or Launch
if [[ -n "$WINDOW_ADDRESS" && "$WINDOW_ADDRESS" != "null" ]]; then
  hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
  eval exec setsid "$LAUNCH_COMMAND"
fi
