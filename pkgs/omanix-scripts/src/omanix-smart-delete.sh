#!/usr/bin/env bash
# omanix-smart-delete: Smart delete line based on window class
# Injects appropriate shortcut for terminal vs GUI applications

# 1. Get info about the currently active window
ACTIVE=$(hyprctl activewindow -j)
CLASS=$(echo "$ACTIVE" | jq -r ".class")
ADDRESS=$(echo "$ACTIVE" | jq -r ".address")

# Target specific window by address to ensure focus doesn't drift
TARGET="address:$ADDRESS"

# 2. Check if it's a terminal
if [[ "$CLASS" =~ "ghostty" || "$CLASS" =~ "kitty" || "$CLASS" =~ "Alacritty" || "$CLASS" =~ "neovide" ]]; then
  # Terminal: Send Ctrl + U (Standard Unix "Kill Line Backward")
  hyprctl dispatch sendshortcut "CTRL, U, $TARGET"
else
  # Browsers/GUIs: Send Shift + Home (Select to start) then Backspace (Delete selection)
  hyprctl dispatch sendshortcut "SHIFT, Home, $TARGET"
  hyprctl dispatch sendshortcut ", Backspace, $TARGET"
fi
