#!/bin/bash

# omanix:summary=Launch the Omanix screensaver: one ttfx terminal per monitor.
# omanix:args=
# omanix:examples=omanix-launch-screensaver

usage() {
  cat <<USAGE
Usage: omanix-launch-screensaver

Spawns a fullscreen terminal (class org.omanix.screensaver) running
omanix-screensaver on every monitor, mirroring omarchy. The emulator and its
zero-padding config come from OMANIX_SCREENSAVER_TERM / OMANIX_SCREENSAVER_TERM_CONFIG
(baked from omanix.terminal.{bin,screensaverConfig}). Invoked by the omanix.idle
shell service at the screensaver timeout and by the system menu.
USAGE
}

case "${1:-}" in
  -h | --help) usage; exit 0 ;;
  "") ;;
  *) echo "Unknown argument: $1" >&2; exit 1 ;;
esac

# Already running? Leave it be.
pgrep -f '[o]rg.omanix.screensaver' >/dev/null && exit 0

term="${OMANIX_SCREENSAVER_TERM:-ghostty}"
config="${OMANIX_SCREENSAVER_TERM_CONFIG:-}"

focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Omanix's Hyprland evaluates `hyprctl dispatch` arguments as Lua (hl.dsp.*), so
# the classic string dispatchers are a Lua syntax error there. Use the Lua form
# and fall back to the classic dispatcher for a non-Lua Hyprland.
hypr_focus_monitor() {
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$1\" })" >/dev/null 2>&1 || hyprctl dispatch focusmonitor "$1" >/dev/null
}

hypr_exec() {
  local command
  printf -v command '%q ' "$@"
  hyprctl dispatch "hl.dsp.exec_cmd([[$command]])" >/dev/null 2>&1 || hyprctl dispatch exec -- bash -lc "$command" >/dev/null
}

# Open Hyprland's event stream before spawning anything, so a terminal that maps
# quickly can't emit its openwindow event before we are listening for it.
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
exec {events}< <(socat -U - "UNIX-CONNECT:$SOCKET")

# hypr_exec is async and the new window maps on whatever monitor is focused at
# that moment. Block until this monitor's screensaver actually opens before
# moving focus on -- otherwise slow-starting terminals all pile onto the last
# monitor. The deadline is a safety net in case the window never appears.
wait_for_screensaver_window() {
  local line deadline=$((SECONDS + 5))
  while ((SECONDS < deadline)) && IFS= read -r -t $((deadline - SECONDS)) -u "$events" line; do
    [[ $line == openwindow\>\>*,org.omanix.screensaver,* ]] && return 0
  done
}

for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hypr_focus_monitor "$m"

  case "$term" in
    foot)
      # foot ignores -e (xterm compat); --config replaces its config.
      hypr_exec foot --app-id=org.omanix.screensaver ${config:+--config="$config"} -e omanix-screensaver
      ;;
    *)
      # ghostty (default): --config-file merges over the user config.
      hypr_exec ghostty --class=org.omanix.screensaver ${config:+--config-file="$config"} --font-size=18 -e omanix-screensaver
      ;;
  esac

  wait_for_screensaver_window
done

hypr_focus_monitor "$focused"
