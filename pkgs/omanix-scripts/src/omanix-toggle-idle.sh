#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-idle-inhibited"

idle_on() {
  systemctl --user start hypridle.service 2>/dev/null
  rm -f "$STATE_FILE"
  [[ -t 0 ]] || notify-send "Idle" "Idle rules enabled"
}

idle_off() {
  systemctl --user stop hypridle.service 2>/dev/null
  pkill -f 'omanix-screensaver' 2>/dev/null
  touch "$STATE_FILE"
  [[ -t 0 ]] || notify-send "Idle" "Idle rules disabled"
}

show_status() {
  if systemctl --user is-active --quiet hypridle.service 2>/dev/null; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status) show_status ;;
  --on)     idle_on ;;
  --off)    idle_off ;;
  *)
    if systemctl --user is-active --quiet hypridle.service 2>/dev/null; then
      idle_off
    else
      idle_on
    fi
    ;;
esac
