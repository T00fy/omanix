#!/usr/bin/env bash

# omanix:summary=Pick one line from stdin via the shell menu (dmenu mode)
# omanix:args=[-p <prompt>] [--width <units>] [--max-height <units>]

set -euo pipefail

prompt="Select"
width=300
max_height=0

while (($# > 0)); do
  case "$1" in
    -p | --prompt | --placeholder)
      prompt="$2"
      shift 2
      ;;
    --width)
      width="$2"
      shift 2
      ;;
    --max-height | --height)
      max_height="$2"
      shift 2
      ;;
    -h | --help)
      echo "Usage: omanix-menu-dmenu [-p <prompt>] [--width <units>] [--max-height <units>] < options"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Newline-delimited options on stdin. Each line may itself carry tab-separated
# "<glyph>\t<label>\t<subtext>" fields per the omanix.menu dmenu contract; the
# picked line comes back on stdout with the glyph stripped.
mapfile -t options
((${#options[@]} > 0)) || exit 0

selection_file=$(mktemp)
done_file=$(mktemp)
rm -f "$done_file"
trap 'rm -f "$selection_file" "$done_file"' EXIT

payload=$(printf '%s\n' "${options[@]}" | jq -R . | jq -s \
  --arg prompt "$prompt" \
  --arg selection "$selection_file" \
  --arg done "$done_file" \
  --argjson width "$width" \
  --argjson maxHeight "$max_height" \
  '{mode: "select", prompt: $prompt, options: ., selectionFile: $selection, doneFile: $done, width: $width, maxHeight: $maxHeight}')

omanix-shell shell summon omanix.menu "$payload" >/dev/null || exit 1

while [[ ! -e $done_file ]]; do
  sleep 0.01
done

if [[ -s $selection_file ]]; then
  cat "$selection_file"
fi
