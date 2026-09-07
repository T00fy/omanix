#!/usr/bin/env bash
# Start and stop a screenrecording of the focused monitor, saved to ~/Videos by default.
# Alternative location via OMARCHY_SCREENRECORD_DIR or XDG_VIDEOS_DIR ENVs.
#
# Uses wl-screenrec (wlroots screencopy + VAAPI hardware encoding). Calling this
# script while a recording is active stops it; otherwise it starts one.
#
# NOTE: This is a departure from Omarchy, which uses gpu-screen-recorder. We
# switched to wl-screenrec because it's far simpler: it captures via Hyprland's
# native wlr-screencopy protocol with no xdg-desktop-portal picker and no
# privileged setcap'd KMS helper — it just works out of the box. The tradeoff
# is no webcam overlay, which gpu-screen-recorder supported; that's an
# intentional drop since I don't use it.

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-screenrecording"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  mkdir -p "$OUTPUT_DIR"
fi

DESKTOP_AUDIO="false"
MICROPHONE_AUDIO="false"
STOP_RECORDING="false"

for arg in "$@"; do
  case "$arg" in
    --with-desktop-audio) DESKTOP_AUDIO="true" ;;
    --with-microphone-audio) MICROPHONE_AUDIO="true" ;;
    --stop-recording) STOP_RECORDING="true" ;;
  esac
done

toggle_screenrecording_indicator() {
  omanix-shell -q omanix.indicators refresh
}

screenrecording_active() {
  [[ -f "$STATE_FILE" ]] && kill -0 "$(cat "$STATE_FILE")" 2>/dev/null
}

start_screenrecording() {
  local filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local monitor
  monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

  if [[ -z "$monitor" ]]; then
    notify-send "Screen recording error" "Could not determine the focused monitor." -u critical -t 3000
    return 1
  fi

  local audio_args=()
  if [[ "$DESKTOP_AUDIO" == "true" || "$MICROPHONE_AUDIO" == "true" ]]; then
    audio_args+=(--audio)
    # wl-screenrec records a single PulseAudio source. Prefer the microphone
    # (default input) when requested, otherwise the default sink's monitor so
    # we capture desktop output. Resolve names now — ffmpeg's pulse layer does
    # not understand pactl's @DEFAULT_*@ tokens.
    if [[ "$MICROPHONE_AUDIO" == "true" ]]; then
      audio_args+=(--audio-device "$(pactl get-default-source)")
    else
      audio_args+=(--audio-device "$(pactl get-default-sink).monitor")
    fi
  fi

  wl-screenrec --output "$monitor" "${audio_args[@]}" --filename "$filename" &
  echo "$!" > "$STATE_FILE"
  notify-send "Screen Recording" "Recording $monitor — press ALT+Print to stop" -t 3000
  toggle_screenrecording_indicator
}

stop_screenrecording() {
  local pid=""
  [[ -f "$STATE_FILE" ]] && pid=$(cat "$STATE_FILE")

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    # wl-screenrec finalizes the mp4 cleanly on SIGINT.
    kill -SIGINT "$pid"

    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 50 ]; do
      sleep 0.1
      count=$((count + 1))
    done

    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid"
      notify-send "Screen recording error" "Recording process had to be force-killed. Video may be corrupted." -u critical -t 5000
    else
      notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
    fi
  else
    # Fallback: process is gone but state may be stale. Reap any stragglers.
    pkill -SIGINT -x wl-screenrec 2>/dev/null
    notify-send "Screen recording stopped" -t 2000
  fi

  rm -f "$STATE_FILE"
  toggle_screenrecording_indicator
}

if screenrecording_active; then
  stop_screenrecording
elif [[ "$STOP_RECORDING" == "true" ]]; then
  # Asked to stop, but nothing is running — clear any stale indicator state.
  rm -f "$STATE_FILE"
  toggle_screenrecording_indicator
else
  start_screenrecording
fi
