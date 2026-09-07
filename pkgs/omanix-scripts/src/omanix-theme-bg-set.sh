#!/bin/bash

# omanix:summary=Set the current background image
# omanix:args=<path-to-image>
# omanix:examples=omanix-theme-bg-set ~/Pictures/background.png

if [[ -z $1 ]]; then
  echo "Usage: omanix-theme-bg-set <path-to-image>" >&2
  exit 1
fi

BACKGROUND="$(realpath "$1")"
CURRENT_BACKGROUND_LINK="$HOME/.local/state/omanix/current/background"

if [[ ! -f $BACKGROUND ]]; then
  echo "File does not exist: $BACKGROUND" >&2
  exit 1
fi

# Ephemeral overlay: repoint the runtime background symlink. A rebuild re-seeds
# it to the declared omanix.activeTheme.assets.wallpaper (see omanixBackgroundState).
mkdir -p "$(dirname "$CURRENT_BACKGROUND_LINK")"
ln -nsf "$BACKGROUND" "$CURRENT_BACKGROUND_LINK"

# Update the live shell background immediately when it is running. The
# background plugin also polls this symlink, but IPC avoids the visible delay.
omanix-shell -q background set "$BACKGROUND"
