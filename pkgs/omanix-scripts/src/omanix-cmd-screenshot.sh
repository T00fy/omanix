#!/usr/bin/env bash

# 1. Determine Output Directory
if [[ -f ~/.config/user-dirs.dirs ]]; then
  source ~/.config/user-dirs.dirs
  OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"
else
  OUTPUT_DIR="$HOME/Pictures"
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  mkdir -p "$OUTPUT_DIR"
fi

# Cleanup any stuck instances
pkill slurp && exit 0
pkill wayfreeze

# Arguments: Mode [smart|region|windows|fullscreen] | Dest [file|clipboard]
MODE="${1:-smart}"
DEST="${2:-file}"

# Helper to get window rectangles from Hyprland
get_rectangles() {
  local active_workspace
  active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
  
  hyprctl monitors -j | jq -r --arg ws "$active_workspace" '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
  hyprctl clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# Start Wayfreeze in background to freeze all monitors
wayfreeze & PID=$!
sleep 0.1

# Selection Logic
case "$MODE" in
  region)
    SELECTION=$(slurp 2>/dev/null)
    ;;
  windows)
    SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
    ;;
  fullscreen)
    SELECTION=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
    ;;
  smart|*)
    RECTS=$(get_rectangles)
    SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)

    # Smart Logic for tiny clicks
    if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
      W="${BASH_REMATCH[3]}"
      H="${BASH_REMATCH[4]}"
      AREA=$(( W * H ))
      
      if (( AREA < 20 )); then
        CLICK_X="${BASH_REMATCH[1]}"
        CLICK_Y="${BASH_REMATCH[2]}"

        while IFS= read -r rect; do
          if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
            RX="${BASH_REMATCH[1]}"
            RY="${BASH_REMATCH[2]}"
            RW="${BASH_REMATCH[3]}"
            RH="${BASH_REMATCH[4]}"

            if (( CLICK_X >= RX && CLICK_X < RX+RW && CLICK_Y >= RY && CLICK_Y < RY+RH )); then
              SELECTION="$RX,$RY ${RW}x${RH}"
              break
            fi
          fi
        done <<< "$RECTS"
      fi
    fi
    ;;
esac

# CRITICAL: Kill wayfreeze and wait for it to fully exit.
# If grim captures while wayfreeze is still active, it can result in a blurry/dim buffer.
kill $PID 2>/dev/null
wait $PID 2>/dev/null
pkill wayfreeze

# If no selection made, exit
[ -z "$SELECTION" ] && exit 0

# Ensure we are focusing the monitor under the cursor so Satty opens there
hyprctl dispatch focusmonitor +0 >/dev/null 2>&1

# Processing Logic
if [[ "$DEST" == "file" ]]; then
  TEMP_FILE="/tmp/omanix-snap-$(date +%s).png"
  FILE_NAME="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
  
  grim -g "$SELECTION" "$TEMP_FILE"
  
  satty --filename "$TEMP_FILE" \
      --output-filename "$FILE_NAME" \
      --early-exit \
      --actions-on-enter save-to-clipboard \
      --save-after-copy \
      --copy-command "wl-copy"
      
  rm -f "$TEMP_FILE"
else
  grim -g "$SELECTION" - | wl-copy
  notify-send "Screenshot copied to clipboard"
fi
