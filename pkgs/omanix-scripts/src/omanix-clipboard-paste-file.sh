#!/bin/bash

# omanix:summary=Copy (and optionally paste) an image/file clipboard-history entry
# omanix:args=[--copy-only] <mime> <path>
# omanix:examples=omanix-clipboard-paste-file image/png ~/.local/state/omanix/clipboard-images/ab.png

set -euo pipefail

copy_only=0
if [[ ${1:-} == "--copy-only" ]]; then
  copy_only=1
  shift
fi

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: omanix-clipboard-paste-file [--copy-only] <mime> <path>"
  exit 0
fi

mime="${1:-}"
path="${2:-}"
[[ -n $mime && -n $path ]] || { echo "Usage: omanix-clipboard-paste-file [--copy-only] <mime> <path>" >&2; exit 1; }
[[ -f $path ]] || { echo "clipboard file not found: $path" >&2; exit 1; }

wl-copy --type "$mime" <"$path"

((copy_only)) && exit 0

wtype -M ctrl -k v -m ctrl
