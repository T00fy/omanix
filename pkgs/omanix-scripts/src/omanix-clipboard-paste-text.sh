#!/bin/bash

# omanix:summary=Copy (and optionally paste) a text clipboard-history entry
# omanix:args=[--shift-insert] [--copy-only] --history-index <n>
# omanix:examples=omanix-clipboard-paste-text --shift-insert --history-index 0

set -euo pipefail

HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/omanix/clipboard-history.json"

shift_insert=0
copy_only=0
index=""

while (($#)); do
  case $1 in
    --shift-insert) shift_insert=1; shift ;;
    --copy-only) copy_only=1; shift ;;
    --history-index) index="${2:-}"; shift 2 ;;
    -h | --help)
      echo "Usage: omanix-clipboard-paste-text [--shift-insert] [--copy-only] --history-index <n>"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ $index =~ ^[0-9]+$ ]] || { echo "--history-index <n> is required" >&2; exit 1; }
[[ -f $HISTORY ]] || { echo "no clipboard history" >&2; exit 1; }

# Read the full text back from history by index (the picker only renders a
# prefix, so this is the untruncated original). Verify it exists and is a text
# entry first — a bad index or non-text entry yields an empty jq stream that
# would otherwise silently blank the clipboard. Never echo the content.
if ! jq -e --argjson i "$index" '.[$i] | select(.type == "text") | .text' "$HISTORY" >/dev/null 2>&1; then
  echo "no text entry at index $index" >&2
  exit 1
fi
# -j: raw output, no trailing newline — copy the exact stored bytes.
jq -je --argjson i "$index" '.[$i].text' "$HISTORY" | wl-copy

((copy_only)) && exit 0

if ((shift_insert)); then
  wtype -M shift -k Insert -m shift
else
  wtype -M ctrl -k v -m ctrl
fi
