#!/bin/bash

# omanix:summary=Open the clipboard history picker, or open one entry externally
# omanix:args=[--history-index <n>]
# omanix:examples=omanix-clipboard-open | omanix-clipboard-open --history-index 0

set -euo pipefail

HISTORY="${XDG_STATE_HOME:-$HOME/.local/state}/omanix/clipboard-history.json"

index=""
while (($#)); do
  case $1 in
    --history-index) index="${2:-}"; shift 2 ;;
    -h | --help)
      echo "Usage: omanix-clipboard-open [--history-index <n>]"
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# No index: this is the keybind opener — toggle the picker over IPC.
if [[ -z $index ]]; then
  omanix-shell shell toggle omanix.clipboard
  exit 0
fi

# With an index: open that entry externally (the picker's "open" action).
[[ $index =~ ^[0-9]+$ ]] || { echo "invalid --history-index: $index" >&2; exit 1; }
[[ -f $HISTORY ]] || { echo "no clipboard history" >&2; exit 1; }

type=$(jq -r --argjson i "$index" '.[$i].type // empty' "$HISTORY")
case $type in
  image)
    path=$(jq -r --argjson i "$index" '.[$i].path // empty' "$HISTORY")
    [[ -n $path ]] && xdg-open "$path" ;;
  text)
    text=$(jq -r --argjson i "$index" '.[$i].text // empty' "$HISTORY")
    # Open only when the entry is a single URL or a file:// path; opening
    # arbitrary text would just spawn an editor on a temp file, which is noise.
    case $text in
      http://* | https://* | file://*) xdg-open "$text" ;;
    esac ;;
  *)
    echo "no entry at index $index" >&2; exit 1 ;;
esac
