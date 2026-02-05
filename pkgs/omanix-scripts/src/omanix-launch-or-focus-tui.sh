#!/usr/bin/env bash

# Usage check
if (($# == 0)); then
  echo "Usage: omanix-launch-or-focus-tui [command] [args...]"
  exit 1
fi

# 1. Determine IDs
# We extract the base name (e.g., 'btop' from 'btop --utf8')
CMD_NAME=$(basename "$1")
# This ID matches the class used in omanix-launch-tui
APP_ID="org.omanix.$CMD_NAME"

# 2. Compose logic
# We call our other scripts. We pass all arguments ($*) to the launch command
# so that flags (like -e or --flags) are preserved if a new window is launched.
exec omanix-launch-or-focus "$APP_ID" "omanix-launch-tui $*"
