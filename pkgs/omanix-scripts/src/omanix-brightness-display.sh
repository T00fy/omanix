#!/usr/bin/env bash

# omanix:summary=Show or adjust brightness on the focused (or named) display
# omanix:args=[--no-osd] [--monitor name] [+N%|N%-|N%|off|on]
# omanix:examples=omanix-brightness-display | omanix-brightness-display --monitor DP-1 50% | omanix-brightness-display off

# Per-monitor brightness for the shell's Display panel. Internal panels
# (eDP/LVDS/DSI) go through brightnessctl on the device omanix-hw-display picks;
# external monitors go through DDC/CI (ddcutil, VCP feature 0x10). With no value
# it prints the current percent, or "unavailable" when there is no controllable
# backlight — the panel greys the slider out on that. This is the panel path;
# omanix-brightness is the separate media-key path.

no_osd=0
monitor=""

while (($# > 0)); do
  case "$1" in
  --no-osd)
    no_osd=1
    shift
    ;;
  --monitor)
    (($# >= 2)) || exit 1
    monitor="$2"
    shift 2
    ;;
  *)
    break
    ;;
  esac
done

# Percent of the internal backlight device.
backlight_brightness() {
  brightnessctl -d "$1" -m 2>/dev/null | awk -F, '{ gsub("%", "", $4); print $4; found=1 } END{ exit !found }'
}

# Focused monitor name when none was given.
[[ -n $monitor ]] || monitor="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || true)"

monitor_is_internal() {
  [[ $monitor =~ ^(eDP|LVDS|DSI)- ]]
}

use_ddc_display() {
  [[ -n $monitor ]] && ! monitor_is_internal && command -v ddcutil >/dev/null 2>&1
}

# Resolve the ddcutil display number for $monitor by matching the DRM connector
# reported by `ddcutil detect`. Falls back to the sole display when only one is
# present, else prints nothing (ambiguous — treated as unavailable).
ddc_display_number() {
  ddcutil detect --terse 2>/dev/null | awk -v mon="$monitor" '
    /^Display / { disp = $2; next }
    /DRM_connector:/ {
      conn = $2
      sub(/^card[0-9]+-/, "", conn)
      if (conn == mon) { print disp; found = 1; exit }
      count++
      last = disp
    }
    END { if (!found && count == 1) print last }
  '
}

ddc_get() {
  local disp="$1"
  ddcutil --display "$disp" getvcp 10 --brief 2>/dev/null |
    awk '$1 == "VCP" { print int($4 * 100 / $5 + 0.5); found = 1 } END { exit !found }'
}

ddc_set() {
  local disp="$1" pct="$2"
  ddcutil --display "$disp" setvcp 10 "$pct" >/dev/null 2>&1
}

# ---- read current brightness (no value argument) ----
if (($# == 0)); then
  if use_ddc_display; then
    disp="$(ddc_display_number)"
    if [[ -n $disp ]] && brightness="$(ddc_get "$disp")"; then
      echo "$brightness"
    else
      echo "unavailable"
    fi
    exit 0
  fi

  device="$(omanix-hw-display)" || {
    echo "unavailable"
    exit 0
  }
  backlight_brightness "$device" || echo "unavailable"
  exit 0
fi

step="$1"

# ---- DPMS off/on ----
if [[ $step == "off" ]]; then
  hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })' >/dev/null 2>&1
  exit 0
elif [[ $step == "on" ]]; then
  # Skip the dispatch when every active display is already lit: a redundant DPMS
  # enable right after resume forces another modeset, blanking the panel for a
  # beat (visible flash at the unlock screen).
  hyprctl monitors -j 2>/dev/null | jq -e '[.[] | select(.disabled == false)] | length > 0 and all(.dpmsStatus)' >/dev/null 2>&1 && exit 0
  hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null 2>&1
  exit 0
fi

# Drop overlapping brightness key events so concurrent invocations do not race.
exec {lock_fd}>"${XDG_RUNTIME_DIR:-/tmp}/omanix-brightness-display.lock"
flock -n "$lock_fd" || exit 0

if use_ddc_display; then
  disp="$(ddc_display_number)"
  [[ -n $disp ]] || exit 1
  # DDC only takes an absolute percentage; strip any trailing % or sign.
  pct="${step%\%}"
  pct="${pct#+}"
  pct="${pct%-}"
  [[ $pct =~ ^[0-9]+$ ]] || exit 1
  ((pct > 100)) && pct=100
  ddc_set "$disp" "$pct" || exit 1
  ((no_osd)) || omanix-osd -i brightness -p "$pct"
else
  device="$(omanix-hw-display)" || exit 1
  brightnessctl -d "$device" set "$step" >/dev/null 2>&1 || exit 1
  ((no_osd)) || omanix-osd -i brightness -p "$(backlight_brightness "$device")"
fi
