#!/usr/bin/env bash

# omanix:summary=Send file(s) to a tailnet machine via Taildrop
# omanix:group=network
# omanix:args=<machine> [file...]
# omanix:examples=omanix-tailscale-send laptop ~/report.pdf

set -uo pipefail

usage() {
  echo "Usage: omanix-tailscale-send <machine> [file...]" >&2
  echo "  With no files, opens a picker. <machine> is a tailnet name/host/IP." >&2
  exit 1
}

machine="${1:-}"
[[ -z "$machine" ]] && usage
shift

files=("$@")

# The shell panel calls us with just the peer address, so fill in the files via
# the floating picker when none were passed on the command line.
if [[ ${#files[@]} -eq 0 ]]; then
  mapfile -t files < <(omanix-file-select)
fi

# Cancelled picker / nothing selected — clean no-op.
[[ ${#files[@]} -eq 0 ]] && exit 0

if tailscale file cp "${files[@]}" "${machine}:"; then
  notify-send "Taildrop" "Sent ${#files[@]} file(s) to ${machine}"
else
  notify-send -u critical "Taildrop" "Failed to send to ${machine}"
  exit 1
fi
