#!/bin/bash

# omanix:summary=Pick a shell plugin to enable or disable
# omanix:name=plugin
# omanix:args=<enable|disable>

set -euo pipefail

PLUGIN_ICON=$'\U000f0431'

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "$@" || true
}

case "${1:-}" in
  enable) filter='(.enabled | not)' ;;
  disable) filter='.canDisable and .enabled' ;;
  *)
    echo "Usage: omanix-menu-plugin <enable|disable>" >&2
    exit 1
    ;;
esac

plugins=$(omanix-plugin-list --json)

# The id rides along as row subtext: it tells same-named plugins apart on
# screen and comes back with the selection as the key to act on.
rows=$(jq -r --arg icon "$PLUGIN_ICON" \
  ". as \$plugins
   | .[] | select($filter)
   | \$icon + \"\\t\" + .name + \"\\t\" + .id" <<<"$plugins")
[[ -n $rows ]] || { notify "No plugin to ${1}"; exit 0; }

# omanix-menu-dmenu returns the picked line with the glyph stripped: "name\tid".
selection=$(omanix-menu-dmenu -p "${1^} plugin" <<<"$rows") || exit 0
[[ -n $selection ]] || exit 0

id=$(cut -f2 <<<"$selection")
[[ -n $id ]] || exit 1

"omanix-plugin-$1" "$id"
