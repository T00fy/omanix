#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active"
OTHER_MONITORS_STATE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-other-monitors"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

refresh_waybar() {
  # Full config/style reload, not RTMIN+9 (which only refreshes a single
  # custom module's icon) — barHeight/fontSize are structural changes.
  pkill -SIGUSR2 waybar 2>/dev/null
}

# Waybar/walker/foot's sizing tables assume a specific compositor scale (see
# waybar.nix's mkBarHeight/mkFontSize: "1" -> normal size, anything else ->
# the 2x-tuned variant).
apply_waybar_variant() {
  local scale="$1" variant
  variant="2x"
  [[ "$scale" == "1" ]] && variant="1x"
  ln -sf "$WAYBAR_DIR/config-${variant}.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-${variant}.css" "$WAYBAR_DIR/style.css"
  refresh_waybar
}

set_monitor_scale() {
  # Only meaningful when omanix.sunshine.scaledDesktop is configured (the
  # env vars are injected from osConfig — see
  # modules/home-manager/scripts/default.nix). Sunshine's own prep-cmd used
  # to run this hyprctl command separately from omanix-scale, which let the
  # two drift apart: triggering omanix-scale from the menu changed
  # waybar/walker/foot's sizing tables (which assume a 2x compositor scale)
  # WITHOUT changing the compositor scale itself, making the UI shrink
  # instead of grow. Owning both here in one place means the menu toggle and
  # the Sunshine prep-cmd can never disagree again.
  [[ -n "$OMANIX_SCALE_MONITOR" ]] || return 0
  hyprctl eval "hl.monitor({ output = '$OMANIX_SCALE_MONITOR', mode = '$OMANIX_SCALE_MODE', position = '$OMANIX_SCALE_POSITION', scale = '$1' })"
}

# Moonlight maps the client's pointer motion onto the streamed monitor's
# logical (post-scale) resolution, so doubling the monitor scale above makes
# the same physical trackpad/mouse movement feel much faster, and the cursor
# bitmap (rendered at a fixed nominal size times the scale factor) grows
# right along with everything else. Both are purely cosmetic/feel issues
# introduced by scaling, so they're corrected here in lockstep with it.
set_pointer_feel() {
  local sensitivity="$1" cursor_size="$2"
  [[ -n "$sensitivity" ]] && hyprctl eval "hl.config({ input = { sensitivity = $sensitivity } })"
  [[ -n "$cursor_size" ]] && hyprctl setcursor "${HYPRCURSOR_THEME:-Adwaita}" "$cursor_size"
}

# Any other connected monitor (a second local display, not the one Sunshine
# streams) has no static mode/position declared anywhere — unlike
# OMANIX_SCALE_MONITOR, it's not configured via omanix.sunshine.scaledDesktop.
# So its current mode/position/scale is read live from Hyprland and
# snapshotted to OTHER_MONITORS_STATE before scaling it up, letting scale_off
# restore the exact prior values instead of guessing a revert factor.
scale_other_monitors_on() {
  : > "$OTHER_MONITORS_STATE"
  hyprctl monitors -j | jq -c '.[] | select(.disabled == false)' | while read -r mon; do
    name=$(jq -r '.name' <<<"$mon")
    [[ "$name" == "$OMANIX_SCALE_MONITOR" ]] && continue
    mode=$(jq -r '"\(.width)x\(.height)@\((.refreshRate * 100 | round) / 100)"' <<<"$mon")
    position=$(jq -r '"\(.x)x\(.y)"' <<<"$mon")
    scale=$(jq -r '.scale' <<<"$mon")
    echo "$name|$mode|$position|$scale" >>"$OTHER_MONITORS_STATE"
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$1' })"
  done
}

scale_other_monitors_off() {
  [[ -f "$OTHER_MONITORS_STATE" ]] || return 0
  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    # Skip monitors that were unplugged since scale_other_monitors_on ran.
    hyprctl monitors -j | jq -e --arg n "$name" '.[] | select(.name == $n and .disabled == false)' >/dev/null 2>&1 || continue
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$scale' })"
  done <"$OTHER_MONITORS_STATE"
  rm -f "$OTHER_MONITORS_STATE"
}

scale_on() {
  set_monitor_scale "$OMANIX_SCALE_FACTOR"
  scale_other_monitors_on "$OMANIX_SCALE_FACTOR"
  set_pointer_feel "$OMANIX_SCALE_SENSITIVITY" "$OMANIX_SCALE_CURSOR_SIZE"
  apply_waybar_variant "$OMANIX_SCALE_FACTOR"
  touch "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI enabled"
}

scale_off() {
  set_monitor_scale "$OMANIX_SCALE_REVERT_FACTOR"
  scale_other_monitors_off
  set_pointer_feel "$OMANIX_SCALE_REVERT_SENSITIVITY" "$OMANIX_SCALE_REVERT_CURSOR_SIZE"
  apply_waybar_variant "$OMANIX_SCALE_REVERT_FACTOR"
  rm -f "$STATE_FILE"
  [[ -t 0 ]] || notify-send "UI Scale" "Scaled UI disabled"
}

show_status() {
  if [[ -f "$STATE_FILE" ]]; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status) show_status ;;
  --on)     scale_on ;;
  --off)    scale_off ;;
  *)
    if [[ -f "$STATE_FILE" ]]; then
      scale_off
    else
      scale_on
    fi
    ;;
esac
