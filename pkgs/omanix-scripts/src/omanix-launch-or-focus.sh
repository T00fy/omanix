#!/usr/bin/env bash

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-or-focus [window-pattern] [launch-command]"
  exit 1
fi

WINDOW_PATTERN="$1"
# Default to launching the pattern via uwsm if no command provided
LAUNCH_COMMAND="${2:-"uwsm app -- $WINDOW_PATTERN"}"

# 1. Query Hyprland for windows matching the class or title (case-insensitive)
# Functional Parity: Uses the exact same jq logic as original
WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" \
  '.[] | select((.class | test($p; "i")) or (.title | test($p; "i"))) | .address' | head -n1)

# 2. Focus or Launch
if [[ -n "$WINDOW_ADDRESS" && "$WINDOW_ADDRESS" != "null" ]]; then
  # Window exists: Focus it
  hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
else
  # Window doesn't exist: Launch new instance
  # setsid detaches the process from the current shell
  eval exec setsid "$LAUNCH_COMMAND"
fi
