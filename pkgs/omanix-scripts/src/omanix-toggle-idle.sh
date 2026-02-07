#!/usr/bin/env bash

if pgrep -x hypridle >/dev/null; then
  pkill -x hypridle
  notify-send "Idle Inhibit" "Stop locking computer when idle"
else
  hypridle &
  notify-send "Idle Inhibit" "Now locking computer when idle"
fi
