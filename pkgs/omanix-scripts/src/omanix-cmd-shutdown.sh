#!/usr/bin/env bash

# Close all windows first to save state
hyprctl clients -j | jq -r ".[].address" | xargs -r -I{} hyprctl dispatch closewindow address:{}
sleep 1
systemctl poweroff
