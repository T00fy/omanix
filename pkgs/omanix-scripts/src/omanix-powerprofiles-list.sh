#!/usr/bin/env bash

# omanix:summary=List power profiles for the shell power panel/menu
# omanix:args=[--active-state]
# omanix:examples=omanix-powerprofiles-list | omanix-powerprofiles-list --active-state

# No args: one profile name per line (the menu snippet pairs each with the
# current profile). --active-state: "name<TAB>flag" lines where flag is 1 for
# the active profile, 0 otherwise (power/Model.js parseProfiles). Needs
# power-profiles-daemon; prints nothing (exit 0) when it is unavailable.

set -uo pipefail

# Profile headers look like "* balanced:" / "  power-saver:"; the driver/degraded
# detail lines below them carry a value after the colon and are skipped.
names=$(powerprofilesctl list 2>/dev/null | awk '
  /^[[:space:]]*\*?[[:space:]]*[a-z-]+:[[:space:]]*$/ {
    line = $0
    sub(/^[[:space:]]*\*?[[:space:]]*/, "", line)
    sub(/:.*$/, "", line)
    if (line != "") print line
  }')
[ -n "$names" ] || exit 0

if [ "${1:-}" = "--active-state" ]; then
  active=$(powerprofilesctl get 2>/dev/null)
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    if [ "$n" = "$active" ]; then
      printf '%s\t1\n' "$n"
    else
      printf '%s\t0\n' "$n"
    fi
  done <<<"$names"
else
  printf '%s\n' "$names"
fi
