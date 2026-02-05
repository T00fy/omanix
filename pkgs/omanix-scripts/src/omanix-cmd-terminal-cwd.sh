#!/usr/bin/env bash

# 1. Get the PID of the currently active window from Hyprland
active_pid=$(hyprctl activewindow -j | jq '.pid')

# 2. Logic to find the current working directory
if [[ -n "$active_pid" && "$active_pid" != "null" ]]; then
  # Find the child process of the terminal (usually the shell)
  shell_pid=$(pgrep -P "$active_pid" | head -n1)
  
  if [[ -n "$shell_pid" ]]; then
    # Resolve the CWD of that process
    readlink -e "/proc/$shell_pid/cwd" || echo "$HOME"
  else
    # If no child shell found, fallback to HOME
    echo "$HOME"
  fi
else
  # If no active window PID found, fallback to HOME
  echo "$HOME"
fi
