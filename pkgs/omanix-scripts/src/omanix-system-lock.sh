#!/bin/bash

# omanix:summary=Lock the session via the Omanix shell lock plugin
# omanix:args=
# omanix:examples=omanix-system-lock

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-system-lock

Locks the session through the omanix.lock shell plugin (in-shell PAM). Invoked
by the omanix.idle service at the lock timeout and by hypridle's lock_cmd (e.g.
on loginctl lock-session before suspend). Any running screensaver overlay is
dismissed afterwards so it is gone on unlock.
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac

omanix-shell lock lock
pkill -f 'omanix-screensaver' 2>/dev/null || true
