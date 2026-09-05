#!/bin/bash

# omanix:summary=Show the Omanix Quickshell on-screen display
# omanix:args=[-i|--icon <icon>] [-m|--message <text>] [-p|--progress <0-100>] [-d|--duration <ms>]
# omanix:examples=omanix-osd -i brightness -p 50 | omanix-osd -m "Hello"

set -euo pipefail

icon=""
message=""
progress=""
progress_text=""
max="100"
duration=""

usage() {
  cat <<USAGE
Usage: omanix-osd [-i|--icon <icon>] [-m|--message <text>] [-p|--progress <0-100>] [-d|--duration <ms>]

Shows the Omanix Quickshell on-screen display overlay. Forwards to the running
shell over IPC; silently no-ops when the shell is not up.

Options:
  -i, --icon <icon>       Icon name (e.g. volume-high, brightness, keyboard).
  -m, --message <text>    Text message (shown without a progress bar).
  -p, --progress <0-100>  Progress value; renders a progress bar.
  -d, --duration <ms>     Auto-hide after <ms> (0 = stay open).

Examples:
  omanix-osd -i brightness -p 50
  omanix-osd -m "Hello"
USAGE
}

while (($#)); do
  case $1 in
    -i|--icon) icon="${2:-}"; shift 2 ;;
    -m|--message) message="${2:-}"; shift 2 ;;
    -p|--progress) progress="${2:-}"; shift 2 ;;
    -d|--duration) duration="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown OSD option: $1" >&2; exit 1 ;;
  esac
done

if [[ -n $progress ]]; then
  progress_text="${progress}%"
fi

payload=$(jq -cn \
  --arg icon "$icon" \
  --arg message "$message" \
  --arg value "$progress" \
  --arg progressText "$progress_text" \
  --arg max "$max" \
  --arg duration "$duration" \
  '{icon:$icon,message:$message,value:$value,progressText:$progressText,max:$max,duration:$duration}')

omanix-shell -q osd show "$payload"
