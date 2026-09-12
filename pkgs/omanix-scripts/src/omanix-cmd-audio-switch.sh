#!/usr/bin/env bash

# omanix:summary=Cycle the default audio output to the next sink and show the OSD

# Get Sinks
SINKS=$(pactl -f json list sinks)
COUNT=$(echo "$SINKS" | jq length)

if [ "$COUNT" -eq 0 ]; then
  omanix-osd -i volume-muted -m "No audio devices"
  exit 1
fi

CURRENT=$(pactl get-default-sink)
NAMES=$(echo "$SINKS" | jq -r '.[].name')

# Cycle logic
NEXT_SINK=""
FOUND_CURRENT=false
FIRST_SINK=""

while IFS= read -r SINK; do
  if [ -z "$FIRST_SINK" ]; then FIRST_SINK="$SINK"; fi

  if [ "$FOUND_CURRENT" = true ]; then
    NEXT_SINK="$SINK"
    break
  fi
  if [ "$SINK" = "$CURRENT" ]; then FOUND_CURRENT=true; fi
done <<<"$NAMES"

if [ -z "$NEXT_SINK" ]; then NEXT_SINK="$FIRST_SINK"; fi

# Resolve the node id so the shell/wireplumber default is set too, then persist
# and move active streams via the shared helper.
NODE_ID=$(echo "$SINKS" | jq -r --arg name "$NEXT_SINK" '.[] | select(.name == $name) | .index')
omanix-audio-output-set-default "${NODE_ID:-0}" "$NEXT_SINK"

DESC=$(echo "$SINKS" | jq -r --arg name "$NEXT_SINK" '.[] | select(.name == $name) | .description')
omanix-osd -i volume-high -m "$DESC"
