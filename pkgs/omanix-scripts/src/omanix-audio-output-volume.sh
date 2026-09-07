#!/bin/bash

# omanix:summary=Adjust output volume (or toggle the mic) and show the Omanix OSD
# omanix:args=<raise|lower|mute-toggle|mic-mute-toggle|+N|-N>
# omanix:examples=omanix-audio-output-volume raise | omanix-audio-output-volume lower | omanix-audio-output-volume mute-toggle | omanix-audio-output-volume +1

action="${1:-}"

if [[ -z $action ]]; then
  echo "Usage: omanix-audio-output-volume <raise|lower|mute-toggle|mic-mute-toggle|+N|-N>"
  exit 1
fi

# Mic mute is the odd one out: it acts on the default *source*, not the resolved
# output sink, and reports through the microphone OSD glyphs. Handle it before
# any sink resolution so a headset with no matching sink still mutes cleanly.
if [[ $action == "mic-mute-toggle" ]]; then
  pactl set-source-mute @DEFAULT_SOURCE@ toggle 2>/dev/null || true
  if [[ $(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null) == *yes ]]; then
    omanix-osd -i microphone-muted -m "Microphone muted"
  else
    omanix-osd -i microphone -m "Microphone on"
  fi
  exit 0
fi

# Resolve through any DSP sink to the physical one, so the keys always move real
# loudness and the processing always sees full-scale input. Shared with the audio
# panel and the output switcher.
sink="$(omanix-audio-output-sink)"
if [[ -z $sink ]]; then
  echo "Could not resolve an audio sink to control." >&2
  exit 1
fi

# pactl reports the same percentage scale wpctl does (both are the raw volume
# over PA_VOLUME_NORM), so the OSD reads identically either way.
volume_percent() {
  pactl get-sink-volume "$sink" 2>/dev/null |
    awk 'NR == 1 {
      for (i = 1; i <= NF; i++)
        if ($i ~ /%$/) {sub("%", "", $i); print $i; exit}
    }'
}

volume_muted() {
  [[ $(pactl get-sink-mute "$sink" 2>/dev/null) == *yes ]]
}

case "$action" in
  raise) action="+5" ;;
  lower) action="-5" ;;
esac

if [[ $action == "mute-toggle" ]]; then
  runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
  debounce_file="$runtime_dir/omanix-audio-output-volume-mute-toggle.last"
  now=$(date +%s%3N)
  last=0
  [[ -r $debounce_file ]] && read -r last <"$debounce_file" || true
  if ((now - last < 250)); then
    exit 0
  fi
  printf '%s\n' "$now" >"$debounce_file"

  pactl set-sink-mute "$sink" toggle
elif [[ $action =~ ^([+-])([0-9]+)$ ]]; then
  direction="${BASH_REMATCH[1]}"
  step="${BASH_REMATCH[2]}"

  current="$(volume_percent)"
  if [[ -z $current ]]; then
    echo "Could not read volume for $sink." >&2
    exit 1
  fi

  if [[ $direction == "+" ]]; then
    next=$((current + step))
    ((next <= 100)) || next=100
  else
    next=$((current - step))
    ((next >= 0)) || next=0
  fi

  pactl set-sink-mute "$sink" 0
  pactl set-sink-volume "$sink" "${next}%"
else
  echo "Unknown volume action: $action"
  exit 1
fi

percent=$(volume_percent)
if volume_muted || ((${percent:-0} == 0)); then
  icon="volume-muted"
else
  icon="volume-high"
fi

omanix-osd -i "$icon" -p "${percent:-0}"
