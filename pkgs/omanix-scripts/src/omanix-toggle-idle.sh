#!/usr/bin/env bash

# omanix:summary=Toggle idle behavior so the system either idles normally or stays awake
# omanix:args=[toggle|stay-awake|allow-idle|status]
# omanix:examples=omanix-toggle-idle | omanix-toggle-idle stay-awake | omanix-toggle-idle status

set -euo pipefail

# Presence of this file means "stay awake": the omanix.idle shell service
# dir-watches it and disables its idle timers (screensaver + lock) while it
# exists. This is the single stay-awake source shared by the menu, the
# Super+Ctrl+I bind, and the bar widget — no daemon to start or stop.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omanix/indicators"
STATE_FILE="$STATE_DIR/stay-awake"

stay_awake_enabled() {
  [[ -f "$STATE_FILE" ]]
}

notify() {
  [[ -t 0 ]] && return 0
  notify-send "Idle" "$1" 2>/dev/null || true
}

apply_state() {
  case "$1" in
    stay-awake)
      mkdir -p "$STATE_DIR"
      touch "$STATE_FILE"
      notify "Staying awake"
      ;;
    allow-idle)
      rm -f "$STATE_FILE"
      notify "Idle rules enabled"
      ;;
  esac
}

print_idle_state() {
  if stay_awake_enabled; then echo "disabled"; else echo "enabled"; fi
}

print_status() {
  if stay_awake_enabled; then
    printf '{"enabled":true,"class":"enabled","tooltip":"Allow Idle Lock & Screensaver"}\n'
  else
    printf '{"enabled":false,"class":"disabled","tooltip":"Stay Awake"}\n'
  fi
}

case "${1:-toggle}" in
  toggle)
    if stay_awake_enabled; then apply_state allow-idle; else apply_state stay-awake; fi
    print_idle_state
    ;;
  stay-awake | awake | on)
    apply_state stay-awake
    print_idle_state
    ;;
  allow-idle | idle | off)
    apply_state allow-idle
    print_idle_state
    ;;
  status | --status) print_status ;;
  -h | --help)
    echo "Usage: omanix-toggle-idle [toggle|stay-awake|allow-idle|status]"
    ;;
  *)
    echo "Usage: omanix-toggle-idle [toggle|stay-awake|allow-idle|status]" >&2
    exit 1
    ;;
esac
