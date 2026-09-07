#!/bin/bash

# omanix:summary=Pick a shell plugin to enable, disable, clone, or remove
# omanix:name=plugin
# omanix:args=<enable|disable|clone|remove>

set -euo pipefail

PLUGIN_ICON=$'\U000f0431'

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send "$@" || true
}

case "${1:-}" in
  enable) filter='(.enabled | not)' ;;
  disable) filter='.canDisable and .enabled' ;;
  clone) filter='.firstParty and (.id as $id | ($plugins | map(.clonedFrom // "") | index($id)) == null)' ;;
  remove) filter='(.firstParty | not)' ;;
  *)
    echo "Usage: omanix-menu-plugin <enable|disable|clone|remove>" >&2
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

if [[ $1 == "clone" ]]; then
  omanix-launch-tui omanix-plugin-clone "$id" --edit
elif [[ $1 == "remove" ]]; then
  omanix-launch-tui omanix-plugin-remove "$id"
else
  "omanix-plugin-$1" "$id"
fi
