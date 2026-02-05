#!/usr/bin/env bash

# Close all windows gracefully before logging out
hyprctl clients -j | jq -r ".[].address" | \
  xargs -r -I{} hyprctl dispatch closewindow address:{}
sleep 0.5
# Exit Hyprland (logs out the session)
hyprctl dispatch exit
