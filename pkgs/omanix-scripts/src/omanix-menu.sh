#!/bin/bash

# omanix:summary=Open the Omanix Quickshell menu / app launcher
# omanix:args=[toggle|show|hide] [<menu-id>]
# omanix:examples=omanix-menu | omanix-menu show system | omanix-menu toggle trigger.capture.screenrecord

set -euo pipefail

usage() {
  cat <<USAGE
Usage: omanix-menu [toggle|show|hide] [<menu-id>]

Drives the omanix.menu Quickshell plugin over IPC. With no menu id the root
menu opens, which doubles as the app launcher (typing there fuzzy-matches
installed apps). A dotted <menu-id> (e.g. system, trigger.capture) opens that
route directly.

Verbs:
  toggle [<menu-id>]  Show the menu, or hide it if already open (default).
  show   [<menu-id>]  Always open (summon) the menu.
  hide                Close the menu.

Examples:
  omanix-menu
  omanix-menu show system
  omanix-menu toggle trigger.capture.screenrecord
USAGE
}

verb="toggle"
menu=""

case "${1:-}" in
  toggle | show) verb="$1"; menu="${2:-}" ;;
  hide) verb="hide"; menu="" ;;
  -h | --help) usage; exit 0 ;;
  "") ;;
  # A bare dotted id (omanix-menu system) toggles that route directly.
  *) menu="$1" ;;
esac

if [[ $verb == hide ]]; then
  omanix-shell shell hide omanix.menu
  exit 0
fi

# "show" maps to the shell's summon (always open); "toggle" is show-or-hide.
method="toggle"
[[ $verb == show ]] && method="summon"

if [[ -n $menu ]]; then
  payload=$(jq -cn --arg menu "$menu" '{menu:$menu}')
  omanix-shell shell "$method" omanix.menu "$payload"
else
  omanix-shell shell "$method" omanix.menu
fi
