#!/usr/bin/env bash
# Start and stop a screenrecording, saved to ~/Videos by default.
# Alternative location via OMARCHY_SCREENRECORD_DIR or XDG_VIDEOS_DIR ENVs.

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-screenrecording"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  mkdir -p "$OUTPUT_DIR"
fi

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"
WEBCAM="false"
WEBCAM_DEVICE=""
STOP_RECORDING="false"

for arg in "$@"; do
  case "$arg" in
    --with-desktop-audio) DESKTOP_AUDIO="true" ;;
    --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
    --with-webcam) WEBCAM="true" ;;
    --webcam-device=*) WEBCAM_DEVICE="${arg#*=}" ;;
    --stop-recording) STOP_RECORDING="true" ;;
  esac
done

cleanup_webcam() {
  pkill -f "WebcamOverlay" 2>/dev/null
}

start_webcam_overlay() {
  cleanup_webcam

  if [[ -z "$WEBCAM_DEVICE" ]]; then
    WEBCAM_DEVICE=$(v4l2-ctl --list-devices 2>/dev/null | grep -m1 "^\s*/dev/video" | tr -d '\t')
    if [[ -z "$WEBCAM_DEVICE" ]]; then
      notify-send "No webcam devices found" -u critical -t 3000
      return 1
    fi
  fi

  local scale=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')
  local target_width=$(awk "BEGIN {printf \"%.0f\", 360 * $scale}")

  local preferred_resolutions=("640x360" "1280x720" "1920x1080")
  local video_size_arg=""
  local available_formats=$(v4l2-ctl --list-formats-ext -d "$WEBCAM_DEVICE" 2>/dev/null)

  for resolution in "${preferred_resolutions[@]}"; do
    if echo "$available_formats" | grep -q "$resolution"; then
      video_size_arg="-video_size $resolution"
      break
    fi
  done

  ffplay -f v4l2 $video_size_arg -framerate 30 "$WEBCAM_DEVICE" \
    -vf "scale=${target_width}:-1" \
    -window_title "WebcamOverlay" \
    -noborder \
    -fflags nobuffer -flags low_delay \
    -probesize 32 -analyzeduration 0 \
    -loglevel quiet &

  sleep 1
}

start_screenrecording() {
  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local audio_devices=""
  local audio_args=""

  [[ "$DESKTOP_AUDIO" == "true" ]] && audio_devices+="default_output"

  if [[ "$MICROPHONE_AUDIO" == "true" ]]; then
    [[ -n "$audio_devices" ]] && audio_devices+="|"
    audio_devices+="default_input"
  fi

  [[ -n "$audio_devices" ]] && audio_args+="-a $audio_devices"

  gpu-screen-recorder -w portal -f 60 -fallback-cpu-encoding yes -o "$filename" $audio_args -ac aac &
  echo "$!" > "$STATE_FILE"
  notify-send "Screen Recording" "Recording started — press ALT+Print to stop" -t 3000
  toggle_screenrecording_indicator
}

stop_screenrecording() {
  local pid=""
  [[ -f "$STATE_FILE" ]] && pid=$(cat "$STATE_FILE")

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill -SIGINT "$pid"

    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 50 ]; do
      sleep 0.1
      count=$((count + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid"
      cleanup_webcam
      notify-send "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
    else
      cleanup_webcam
      notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
    fi
  else
    # Fallback: try pgrep if state file is stale
    pkill -SIGINT -f "gpu-screen-recorder -w" 2>/dev/null
    cleanup_webcam
    notify-send "Screen recording stopped" -t 2000
  fi

  rm -f "$STATE_FILE"
  toggle_screenrecording_indicator
}

toggle_screenrecording_indicator() {
  pkill -RTMIN+8 waybar
}

screenrecording_active() {
  [[ -f "$STATE_FILE" ]] && kill -0 "$(cat "$STATE_FILE")" 2>/dev/null
}

if screenrecording_active; then
  stop_screenrecording
elif pgrep -f "WebcamOverlay" >/dev/null; then
  cleanup_webcam
elif [[ "$STOP_RECORDING" == "false" ]]; then
  [[ "$WEBCAM" == "true" ]] && start_webcam_overlay
  start_screenrecording || cleanup_webcam
else
  exit 1
fi
