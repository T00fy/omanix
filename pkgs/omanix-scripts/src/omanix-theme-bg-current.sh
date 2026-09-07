#!/bin/bash

# omanix:summary=Show current background
# omanix:examples=omanix-theme-bg-current

BACKGROUND_PATH=$(readlink -f "$HOME/.local/state/omanix/current/background" 2>/dev/null)

if [[ -n $BACKGROUND_PATH ]]; then
  basename -- "$BACKGROUND_PATH" | perl -pe 's/\.[^.]+$//; s/^\d+-//; s/-/ /g; s/\b(\w)/\U$1/g'
else
  echo "Unknown"
fi
