#!/bin/bash

# omanix:summary=Type an emoji into the focused window
# omanix:args=<emoji>
# omanix:examples=omanix-menu-emoji-insert 🔥

set -euo pipefail

if [[ $# -ne 1 || ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: omanix-menu-emoji-insert <emoji>" >&2
  [[ ${1:-} == "-h" || ${1:-} == "--help" ]] && exit 0
  exit 1
fi

emoji="$1"

# Put it on the clipboard as a fallback (paste still works if typing is
# swallowed by the focused surface), then type it into the focused window.
wl-copy -- "$emoji" || true
wtype -- "$emoji"
