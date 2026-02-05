#!/usr/bin/env bash
# Cycles through theme wallpapers temporarily (non-persistent across reboots).
# OMANIX_WALLPAPERS is a newline-separated list of paths injected by the Nix wrapper.

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-current-wallpaper"

# Build wallpaper array from env var
mapfile -t WALLPAPERS <<< "$OMANIX_WALLPAPERS"
TOTAL=${#WALLPAPERS[@]}

if [[ $TOTAL -eq 0 || -z "${WALLPAPERS[0]}" ]]; then
  notify-send "No wallpapers found for theme" -t 2000
  exit 1
fi

# Read current wallpaper from state file
CURRENT=""
if [[ -f "$STATE_FILE" ]]; then
  CURRENT=$(cat "$STATE_FILE")
fi

# Find current index
INDEX=-1
for i in "${!WALLPAPERS[@]}"; do
  if [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]]; then
    INDEX=$i
    break
  fi
done

# Get next wallpaper (wrap around)
if [[ $INDEX -eq -1 ]]; then
  NEW_BG="${WALLPAPERS[0]}"
else
  NEXT_INDEX=$(((INDEX + 1) % TOTAL))
  NEW_BG="${WALLPAPERS[$NEXT_INDEX]}"
fi

# Save state
echo "$NEW_BG" > "$STATE_FILE"

# Relaunch swaybg
pkill -x swaybg
setsid swaybg -i "$NEW_BG" -m fill >/dev/null 2>&1 &
