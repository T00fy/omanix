#!/bin/bash

# omanix:summary=Lock the session via the Omanix shell lock plugin
# omanix:args=
# omanix:examples=omanix-system-lock

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-system-lock

Locks the session through the omanix.lock shell plugin (in-shell PAM). Invoked
by the omanix.idle service at the lock timeout and by the lock-before-sleep
inhibitor before the system suspends. Any running screensaver (ttfx terminals)
is dismissed afterwards so it is gone on unlock.
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac

omanix-shell lock lock
# Avoid running the screensaver while locked. ttfx handles SIGTERM
# asynchronously, so kill it first and wait for it to exit before tearing down
# its terminals, otherwise the terminal dies mid-frame.
pkill -x ttfx 2>/dev/null || true
timeout 1s pidwait -x ttfx 2>/dev/null || true
pkill -f '[o]rg.omanix.screensaver' 2>/dev/null || true
