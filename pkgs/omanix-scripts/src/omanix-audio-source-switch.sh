#!/bin/bash

# omanix:summary=Cycle to the next media source and transfer playback when the current source is playing
# omanix:args=[next|previous]
# omanix:examples=omanix-audio-source-switch | omanix-audio-source-switch previous

direction="${1:-next}"

case "$direction" in
  next)
    omanix-shell media sourceSwitch
    ;;
  previous)
    omanix-shell media sourceSwitchPrevious
    ;;
  *)
    echo "Usage: omanix-audio-source-switch [next|previous]" >&2
    exit 1
    ;;
esac
