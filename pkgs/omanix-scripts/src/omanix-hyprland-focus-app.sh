#!/usr/bin/env bash
# Focus a Hyprland window by application identity.
# Usage: omanix-hyprland-focus-app <app-name>

usage() {
  echo "Usage: omanix-hyprland-focus-app <app-name>" >&2
  exit 1
}

app=${1:-}
[[ -n $app ]] || usage

# Agent terminals notify as kitty/foot/etc. while their shared window class is
# org.omanix.agent, leaving the terminal name only in initialTitle. So match
# by class first, then fall back to the launch-time title of agent windows.
address=$(
  hyprctl clients -j 2>/dev/null |
    jq -r --arg pattern "$app" \
      'def matches($value): ($value // "") | test($pattern; "i");
       first(
         (.[] | select(matches(.class))),
         (.[] | select(.initialClass == "org.omanix.agent" and matches(.initialTitle)))
       ).address // empty'
)

[[ -n $address ]] || exit 1

hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null 2>&1 ||
  hyprctl dispatch focuswindow "address:$address" >/dev/null
