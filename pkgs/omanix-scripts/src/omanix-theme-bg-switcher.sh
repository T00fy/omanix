#!/bin/bash

# omanix:summary=Open the Omanix background switcher

# Backgrounds come from the active theme only: current/theme is the store slug
# repointed by activation / omanix-theme-set, and its backgrounds/ subdir is
# baked from the theme's declared assets.wallpapers.
current_background=$(readlink -f "$HOME/.local/state/omanix/current/background" 2>/dev/null)

omanix-menu-images \
  --selected "$current_background" \
  "$HOME/.local/state/omanix/current/theme/backgrounds"
