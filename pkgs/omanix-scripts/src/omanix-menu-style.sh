#!/usr/bin/env bash

# omanix:summary=Pick a theme (shell menu), then its wallpaper

set -euo pipefail

theme=$(jq -r 'keys[]' "$OMANIX_THEMES_FILE" | omanix-menu-dmenu -p "Change Theme")
[[ -z $theme ]] && exit 0

# Palette switch (repoints current/theme + re-themes a running shell).
omanix-theme-set "$theme"

# Wallpaper is a separate axis; open the switcher for the now-current theme.
omanix-theme-bg-switcher
