#!/bin/bash

# omanix:summary=Adjust display backlight brightness and show the Omanix OSD
# omanix:args=<up|down|+N|-N>
# omanix:examples=omanix-brightness up | omanix-brightness down | omanix-brightness +1

# A lightweight brightnessctl producer for the media keys: adjust the backlight
# and surface the level through the shell OSD. The shell's monitor panel drives
# per-monitor brightness itself; this is the keyboard path.

action="${1:-}"

case "$action" in
  up) delta="5%+" ;;
  down) delta="5%-" ;;
  +*[0-9]) delta="${action#+}%+" ;;
  -*[0-9]) delta="${action#-}%-" ;;
  *)
    echo "Usage: omanix-brightness <up|down|+N|-N>" >&2
    exit 1
    ;;
esac

brightnessctl -q set "$delta" 2>/dev/null || true

# brightnessctl -m prints "device,class,current,percent%,max"; take the percent.
percent="$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 {gsub("%", "", $4); print $4; exit}')"

omanix-osd -i brightness -p "${percent:-0}"
