#!/usr/bin/env bash

# Lock the screen immediately
pidof hyprlock || hyprlock &

# Reset keyboard layout to default (security best practice)
hyprctl switchxkblayout all 0 > /dev/null 2>&1

# Bitwarden CLI Lock (Optional integration)
if command -v bw &> /dev/null; then
  if bw status | grep -q "unlocked"; then
    bw lock
    notify-send "Vault Locked" "Bitwarden CLI vault has been locked."
  fi
fi
