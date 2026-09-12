#!/usr/bin/env bash

# omanix:summary=Set the power profile for the shell power panel/menu
# omanix:args=<battery|ac|autodetect> [profile]
# omanix:examples=omanix-powerprofiles-set ac performance | omanix-powerprofiles-set battery

# With an explicit profile (panel: "<battery|ac> <profile>"; menu: "autodetect
# <profile>") that profile is applied directly. With only a power source
# (battery service: "<battery|ac>") the profile is auto-mapped to the best
# available one for that source. Needs power-profiles-daemon.

set -uo pipefail

source="${1:-}"
profile="${2:-}"
[ -n "$source" ] || { echo "Usage: omanix-powerprofiles-set <battery|ac|autodetect> [profile]" >&2; exit 2; }

avail=$(powerprofilesctl list 2>/dev/null | awk '
  /^[[:space:]]*\*?[[:space:]]*[a-z-]+:[[:space:]]*$/ {
    line = $0
    sub(/^[[:space:]]*\*?[[:space:]]*/, "", line)
    sub(/:.*$/, "", line)
    if (line != "") print line
  }')

has() { printf '%s\n' "$avail" | grep -qx "$1"; }

# First available of the preference list.
pick() {
  local p
  for p in "$@"; do
    has "$p" && { printf '%s' "$p"; return 0; }
  done
  return 1
}

if [ -z "$profile" ]; then
  case "$source" in
    battery) profile=$(pick power-saver balanced performance) ;;
    ac) profile=$(pick balanced performance power-saver) ;;
    *) echo "Unknown power source: $source" >&2; exit 2 ;;
  esac
fi

[ -n "$profile" ] || { echo "No applicable power profile" >&2; exit 1; }
powerprofilesctl set "$profile"
