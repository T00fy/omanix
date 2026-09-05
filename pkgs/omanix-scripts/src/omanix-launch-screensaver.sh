#!/bin/bash

# omanix:summary=Launch the Omanix screensaver overlay
# omanix:args=
# omanix:examples=omanix-launch-screensaver

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-launch-screensaver

Launches the GTK layer-shell screensaver (omanix-screensaver). Invoked by the
omanix.idle shell service at the screensaver timeout. The declared logo path is
baked in via OMANIX_SCREENSAVER_LOGO (omanix.idle.screensaver.logo); when unset
the screensaver renders its built-in default.
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac

exec omanix-screensaver ${OMANIX_SCREENSAVER_LOGO:+--logo "$OMANIX_SCREENSAVER_LOGO"}
