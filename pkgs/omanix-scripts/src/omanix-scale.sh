#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active"
OTHER_MONITORS_STATE="${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-other-monitors"
DUMMY_STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/omanix-dummy-display-active"
DUMMY_HIDDEN_WINDOWS_STATE="${XDG_RUNTIME_DIR:-/tmp}/omanix-dummy-display-hidden-windows"
WAYBAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

# Settle delay between monitor-state hyprctl calls in the dummy-display
# orchestration below. NOT a Nix-tunable option — this is purely an
# implementation detail to avoid the stall described in wait_for_monitor_state.
DUMMY_SETTLE_SECONDS=1.5

refresh_waybar() {
  # Full config/style reload, not RTMIN+9 (which only refreshes a single
  # custom module's icon) — barHeight/fontSize are structural changes.
  pkill -SIGUSR2 waybar 2>/dev/null
}

# Full systemd restart, not refresh_waybar's SIGUSR2. SIGUSR2 only tells a
# running waybar process to re-read its config content — it doesn't tear
# down and recreate the per-monitor bar windows waybar keeps internally. For
# scaledDesktop (scale_on/off) that's fine, since it only rescales a monitor
# that was already there. dummyDisplay actually adds/removes a monitor, and
# SIGUSR2 alone can leave a stale bar window from a now-disabled monitor
# bleeding into whatever's left — observed as a disabled monitor's own
# workspace icons appearing spliced into the streamed monitor's bar. A full
# restart guarantees waybar re-queries the compositor's current monitor list
# from scratch and creates exactly one clean bar window per active monitor.
restart_waybar() {
  systemctl --user restart waybar.service 2>/dev/null
}

# Waybar/walker/foot's sizing tables assume a specific compositor scale (see
# waybar.nix's mkBarHeight/mkFontSize: "1" -> normal size, anything else ->
# the 2x-tuned variant). Shared by both scaledDesktop (scale_on/off) and
# dummyDisplay (dummy_display_on/off) so the two toggles can never disagree
# about which variant is correct for a given scale value. "$2" selects
# refresh_waybar (SIGUSR2, cheap, sufficient when the monitor list itself
# isn't changing) vs restart_waybar (see above) — default is refresh.
apply_waybar_variant() {
  local scale="$1" restart="${2:-}" variant
  variant="2x"
  [[ "$scale" == "1" ]] && variant="1x"
  ln -sf "$WAYBAR_DIR/config-${variant}.json" "$WAYBAR_DIR/config"
  ln -sf "$WAYBAR_DIR/style-${variant}.css" "$WAYBAR_DIR/style.css"
  if [[ "$restart" == "restart" ]]; then
    restart_waybar
  else
    refresh_waybar
  fi
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

# Polls `hyprctl monitors -j` for a monitor named "$1" to reach enabled-state
# "$2" (true/false) within a few seconds. Twice during development, chaining
# `hyprctl eval hl.monitor(...)` calls back-to-back (in particular, ever
# passing through a moment where ZERO monitors were enabled) put Hyprland's
# DRM/render thread into a state where hyprctl's IPC kept replying "ok" to
# every command while nothing was actually changing on screen — both real
# monitors went black and stayed that way until recovery. `hyprctl reload`
# (NOT a full Hyprland restart) reliably un-stuck it within ~1s both times.
# This defensive check exists so that failure mode self-heals instead of
# requiring a human to notice and intervene.
wait_for_monitor_state() {
  local name="$1" want_enabled="$2" tries=0
  while (( tries < 4 )); do
    local disabled
    disabled=$(hyprctl monitors -j | jq -r --arg n "$name" '.[] | select(.name == $n) | .disabled')
    if [[ "$want_enabled" == "true" && "$disabled" == "false" ]]; then
      return 0
    elif [[ "$want_enabled" == "false" && ( -z "$disabled" || "$disabled" == "true" ) ]]; then
      return 0
    fi
    sleep 0.5
    (( tries++ ))
  done
  notify-send "Dummy Display" "Monitor state didn't apply as expected, recovering..." 2>/dev/null
  hyprctl reload
  sleep 1
}

# Disabling a real monitor doesn't destroy the workspaces that still have
# windows open on it — Hyprland has to give them a new home, and since the
# dummy connector is the only monitor left enabled at that point, it
# reassigns those occupied workspaces (and their windows) onto the dummy
# display directly. That means anything left open on a real monitor becomes
# visible AND reachable on the streamed display — observed as another
# monitor's own workspace icons and actual window content bleeding into the
# stream. Moving each window to a per-monitor special workspace (hidden,
# unreachable via normal workspace switching) before disabling the monitor
# avoids this; moving them back on disconnect restores exactly what was
# there. Uses `hl.dsp.window.move({ window = 'address:0x...', workspace =
# 'special:...' })`, confirmed live — NOT `hl.window.move` (that path doesn't
# exist; window/workspace dispatchers live under hl.dsp, same as hl.monitor).
hide_windows_on_monitor() {
  local monitor_name="$1" monitor_id
  monitor_id=$(hyprctl monitors -j | jq -r --arg n "$monitor_name" '.[] | select(.name == $n) | .id')
  [[ -n "$monitor_id" ]] || return 0
  hyprctl clients -j | jq -c --argjson id "$monitor_id" '.[] | select(.monitor == $id)' | while read -r client; do
    local address ws
    address=$(jq -r '.address' <<<"$client")
    ws=$(jq -r '.workspace.name' <<<"$client")
    echo "$address|$ws" >>"$DUMMY_HIDDEN_WINDOWS_STATE"
    hyprctl eval "hl.dispatch(hl.dsp.window.move({ window = 'address:$address', workspace = 'special:omanixdummyhidden_$monitor_name', follow = false }))"
  done
}

restore_hidden_windows() {
  [[ -f "$DUMMY_HIDDEN_WINDOWS_STATE" ]] || return 0
  while IFS='|' read -r address ws; do
    [[ -n "$address" ]] || continue
    # Retries a few times with a short delay: right after a real monitor is
    # re-enabled, its workspaces may not be fully recreated yet, and moving
    # a window into a not-yet-existent workspace fails silently (observed
    # live: the monitor re-enabled first in the loop above consistently
    # failed to restore, while one re-enabled later — more settled by the
    # time this ran — succeeded). Also covers a window having been closed
    # while hidden, in which case every retry harmlessly no-ops.
    local tries=0
    while (( tries < 4 )); do
      local clients_json
      clients_json=$(hyprctl clients -j)
      # Window closed while hidden — nothing left to restore.
      jq -e --arg a "$address" '.[] | select(.address == $a)' <<<"$clients_json" >/dev/null 2>&1 || break
      # Already restored (moved out of the hidden special workspace) — done.
      jq -e --arg a "$address" '.[] | select(.address == $a and (.workspace.name | startswith("special:omanixdummyhidden") | not))' <<<"$clients_json" >/dev/null 2>&1 && break
      hyprctl eval "hl.dispatch(hl.dsp.window.move({ window = 'address:$address', workspace = '$ws', follow = false }))" 2>/dev/null
      sleep 0.5
      (( tries++ ))
    done
  done <"$DUMMY_HIDDEN_WINDOWS_STATE"
  rm -f "$DUMMY_HIDDEN_WINDOWS_STATE"
}

# Orchestrates which monitors are enabled so Sunshine's Wayland capture has
# exactly one candidate output (the dummy plug) to auto-select — no
# `output_name` override needed, confirmed Sunshine picks whichever monitor
# is the sole enabled one.
#
# ORDERING IS SAFETY-CRITICAL, do not "simplify" into fewer/batched calls:
#   connect:    enable dummy FIRST, then disable real monitors one at a time
#   disconnect: enable real monitors one at a time FIRST, then disable dummy
# At every step, at least one monitor must remain enabled. Going through a
# moment with zero enabled monitors is exactly what triggered the DRM stall
# above during testing. A settle delay between EVERY hyprctl eval call is
# also required — the stall was also observed when calls were fired without
# one, even when never reaching zero enabled monitors.
#
# Real monitors normally use Hyprland's "auto" position (see
# omanix.monitors.position) — but "auto" re-flows EVERY auto-positioned
# monitor whenever any monitor's enabled state changes, so enabling/disabling
# the dummy plug would otherwise silently shift your real monitors to new
# positions. This is why OMANIX_DUMMY_DISPLAY_REAL_MONITORS carries each real
# monitor's exact mode/position/scale: every hyprctl eval call below sets them
# explicitly, so "auto" is never in play for any monitor this script touches.
#
# apply_waybar_variant below is called with the dummy connector's OWN scale
# on connect (that's what's actually rendered on the streamed monitor,
# unlike scaledDesktop where a single real monitor is both scaled and
# rendered), and with the real monitors' scale on disconnect. Deliberately
# called AFTER the monitor topology has fully settled (real monitors already
# disabled on connect / already re-enabled on disconnect), with the "restart"
# variant, not refresh_waybar's SIGUSR2 — restarting waybar while monitors
# are still mid-transition would just recreate the same stale-bar-window
# problem restart_waybar exists to fix.
dummy_display_on() {
  [[ -n "$OMANIX_DUMMY_DISPLAY_CONNECTOR" ]] || return 0
  # Optional overrides, used by --dummy-on-client; default to the configured
  # dummyDisplay mode/scale.
  local mode="${1:-$OMANIX_DUMMY_DISPLAY_MODE}" scale="${2:-$OMANIX_DUMMY_DISPLAY_SCALE}"

  hyprctl eval "hl.monitor({ output = '$OMANIX_DUMMY_DISPLAY_CONNECTOR', mode = '$mode', position = '$OMANIX_DUMMY_DISPLAY_POSITION', scale = '$scale', disabled = false })"
  wait_for_monitor_state "$OMANIX_DUMMY_DISPLAY_CONNECTOR" true
  sleep "$DUMMY_SETTLE_SECONDS"

  set_pointer_feel "$OMANIX_DUMMY_DISPLAY_SENSITIVITY" "$OMANIX_DUMMY_DISPLAY_CURSOR_SIZE"

  : > "$DUMMY_HIDDEN_WINDOWS_STATE"
  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    # Hide BEFORE disabling — once the monitor is disabled, Hyprland will
    # have already reassigned its occupied workspaces elsewhere, which is
    # exactly the bleed-through this is meant to prevent.
    hide_windows_on_monitor "$name"
    hyprctl eval "hl.monitor({ output = '$name', disabled = true })"
    wait_for_monitor_state "$name" false
    sleep "$DUMMY_SETTLE_SECONDS"
  done <<< "$OMANIX_DUMMY_DISPLAY_REAL_MONITORS"

  apply_waybar_variant "$scale" restart

  touch "$DUMMY_STATE_FILE"
  [[ -t 0 ]] || notify-send "Dummy Display" "Streaming display enabled"
}

# omanix.sunshine.dummyDisplay.apps: the same swap, but at the mode the
# Moonlight client asked for (Sunshine exports SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS
# to prep-cmd) and scale 1, e.g. 3840x2160@60 for a TV. Games under XWayland
# would render at reduced resolution on a 2x-scaled output. Falls back to the
# configured mode when run outside Sunshine.
dummy_display_on_client() {
  local mode="$OMANIX_DUMMY_DISPLAY_MODE"
  if [[ -n "${SUNSHINE_CLIENT_WIDTH:-}" && -n "${SUNSHINE_CLIENT_HEIGHT:-}" ]]; then
    mode="${SUNSHINE_CLIENT_WIDTH}x${SUNSHINE_CLIENT_HEIGHT}@${SUNSHINE_CLIENT_FPS:-60}"
  fi
  dummy_display_on "$mode" 1
}

# OMANIX_DUMMY_DISPLAY_REAL_MONITORS is a static list baked in by the Nix
# wrapper (from omanix.sunshine.dummyDisplay.realMonitors), identical on
# every invocation — unlike scale_other_monitors_on/off's snapshot, which
# captures genuinely dynamic state discovered at runtime, there's nothing to
# snapshot here: the real monitors' normal mode/position/scale are already
# fully known ahead of time, so --dummy-off can restore them directly from
# the env var with no state file to go stale or go missing.
dummy_display_off() {
  [[ -n "$OMANIX_DUMMY_DISPLAY_CONNECTOR" ]] || return 0

  local first_real_scale=""
  while IFS='|' read -r name mode position scale; do
    [[ -n "$name" ]] || continue
    [[ -z "$first_real_scale" ]] && first_real_scale="$scale"
    hyprctl eval "hl.monitor({ output = '$name', mode = '$mode', position = '$position', scale = '$scale', disabled = false })"
    wait_for_monitor_state "$name" true
    sleep "$DUMMY_SETTLE_SECONDS"
  done <<< "$OMANIX_DUMMY_DISPLAY_REAL_MONITORS"

  # Real monitors are back and their workspaces exist again — safe to move
  # windows back into them now.
  restore_hidden_windows

  set_pointer_feel "$OMANIX_DUMMY_DISPLAY_REVERT_SENSITIVITY" "$OMANIX_DUMMY_DISPLAY_REVERT_CURSOR_SIZE"

  hyprctl eval "hl.monitor({ output = '$OMANIX_DUMMY_DISPLAY_CONNECTOR', disabled = true })"
  wait_for_monitor_state "$OMANIX_DUMMY_DISPLAY_CONNECTOR" false

  # Real monitors' own scale (restored above) drives which waybar variant is
  # correct locally — not a hardcoded "1x", since a host could run its real
  # monitors scaled too. All real monitors normally share the same local
  # desktop scale, so the first one's value is representative. Called last,
  # after the dummy connector is fully disabled, for the same "topology must
  # be settled first" reason as dummy_display_on above.
  apply_waybar_variant "$first_real_scale" restart

  rm -f "$DUMMY_STATE_FILE"
  [[ -t 0 ]] || notify-send "Dummy Display" "Streaming display disabled"
}

show_dummy_status() {
  if [[ -f "$DUMMY_STATE_FILE" ]]; then
    echo "on"
    exit 0
  else
    echo "off"
    exit 1
  fi
}

case "${1:-}" in
  --status)      show_status ;;
  --on)          scale_on ;;
  --off)         scale_off ;;
  --dummy-status) show_dummy_status ;;
  --dummy-on)    dummy_display_on ;;
  --dummy-on-client) dummy_display_on_client ;;
  --dummy-off)   dummy_display_off ;;
  *)
    if [[ -f "$STATE_FILE" ]]; then
      scale_off
    else
      scale_on
    fi
    ;;
esac
