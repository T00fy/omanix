#!/usr/bin/env bash

# omanix:summary=Detect clamshell mode: lid closed with an external display (exit code)

# Clamshell = the laptop runs headless-lid on an external monitor. True when the
# lid is closed AND at least one external (non-internal) DRM connector is
# connected. Exits 0 clamshell, 1 otherwise.
omanix-hw-laptop-closed || exit 1

# Internal panels are eDP / LVDS / DSI; anything else connected is external.
for status in /sys/class/drm/*/status; do
  [ -e "$status" ] || continue
  connector=${status%/status}
  connector=${connector##*/}
  case "$connector" in
    *eDP* | *LVDS* | *DSI*) continue ;;
  esac
  grep -qx connected "$status" 2>/dev/null && exit 0
done

exit 1
