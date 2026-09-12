#!/bin/bash

# omanix:summary=Restore displays on wake from idle
# omanix:args=
# omanix:examples=omanix-system-wake

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-system-wake

Best-effort wake handler invoked by the omanix.idle service (and the omanix.lock
plugin) when activity ends an idle cycle. Ensures displays are powered back on.
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac

hyprctl dispatch dpms on 2>/dev/null || true
