#!/bin/bash

# omanix:summary=Open the Omanix emoji picker
# omanix:args=[toggle|show|hide]
# omanix:examples=omanix-menu-emoji | omanix-menu-emoji show | omanix-menu-emoji hide

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-menu-emoji [toggle|show|hide]

Drives the omanix.emojis Quickshell plugin over IPC. Search matches emoji
keywords; selecting one types it into the focused window via
omanix-menu-emoji-insert.

Verbs:
  toggle  Show the picker, or hide it if already open (default).
  show    Always open (summon) the picker.
  hide    Close the picker.
USAGE
}

verb="toggle"
case "${1:-}" in
  toggle | show | hide) verb="$1" ;;
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown verb: $1" >&2; exit 1 ;;
esac

if [[ $verb == hide ]]; then
  omanix-shell shell hide omanix.emojis
  exit 0
fi

# "show" maps to summon (always open); "toggle" is show-or-hide.
method="toggle"
[[ $verb == show ]] && method="summon"
omanix-shell shell "$method" omanix.emojis
