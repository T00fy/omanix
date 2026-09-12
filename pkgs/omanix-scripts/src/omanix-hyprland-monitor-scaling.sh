#!/usr/bin/env bash

# omanix:summary=Show, set, or adjust focused Hyprland monitor scaling
# omanix:args=[up|down|SCALE]
# omanix:examples=omanix-hyprland-monitor-scaling | omanix-hyprland-monitor-scaling 1.6 | omanix-hyprland-monitor-scaling up

# Runtime-only ephemeral overlay: apply a compositor scale to the focused
# monitor via `hyprctl eval hl.monitor(...)`. The declared default lives in
# `omanix.monitor.scale` and is re-asserted into the generated Hyprland config
# (visuals.nix / monitors.nix) on every rebuild, so nothing is persisted here —
# unlike omarchy, we deliberately do NOT sed monitors.lua (it is a read-only
# store file) and do not touch GDK_SCALE (declared in visuals.nix).

SCALES=(1 1.25 1.6 2 3 4)

usage() {
  echo "Usage: omanix-hyprland-monitor-scaling [up|down|SCALE]"
}

focused_monitor_scale() {
  hyprctl monitors -j | jq -er '.[] | select(.focused == true) | .scale'
}

# Hyprland only accepts scales where the mode divides into whole logical
# pixels (in 1/120 steps), so clean scales are divisors of gcd(w*120, h*120).
# Round the requested scale up to the nearest clean value.
clean_scale() {
  awk -v scale="$1" -v width="$2" -v height="$3" '
    function gcd(a, b, t) { while (b) { t = a % b; a = b; b = t } return a }
    BEGIN {
      g = gcd(width * 120, height * 120)
      k = int(scale * 120 + 0.5)
      if (k > g) k = g
      while (g % k != 0) k++
      printf "%g\n", k / 120
    }'
}

normalize_scale() {
  awk 'NR == 1 { printf "%g\n", $0 }'
}

set_scale() {
  local requested_scale="$1"
  local monitor_info="$(hyprctl monitors -j | jq -e -c '.[] | select(.focused == true)')"
  local active_monitor="$(echo "$monitor_info" | jq -r '.name')"
  local width="$(echo "$monitor_info" | jq -r '.width')"
  local height="$(echo "$monitor_info" | jq -r '.height')"
  local refresh_rate="$(echo "$monitor_info" | jq -r '.refreshRate')"

  # active_monitor is written into the Lua string eval'd below, so only a plain
  # connector name may pass; a hostile output name could execute otherwise.
  if [[ ! $active_monitor =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Refusing unsafe monitor name" >&2
    exit 1
  fi

  local new_scale="$(clean_scale "$requested_scale" "$width" "$height")"

  hyprctl eval "hl.monitor({ output = \"$active_monitor\", mode = \"${width}x${height}@${refresh_rate}\", position = \"auto\", scale = $new_scale })" >/dev/null
}

scale_from_current() {
  local direction="${1:-}"
  local width="${2:-}"
  local height="${3:-}"

  awk -v direction="$direction" -v list="${SCALES[*]}" -v width="$width" -v height="$height" '
    function gcd(a, b, t) { while (b) { t = a % b; a = b; b = t } return a }
    function clean(scale,    g, k) {
      g = gcd(width * 120, height * 120)
      k = int(scale * 120 + 0.5)
      if (k > g) k = g
      while (g % k != 0) k++
      return k / 120
    }
    NR == 1 { scale = $0; found = 1 }
    END {
      if (!found) exit 1

      preset_count = split(list, presets, " ")
      for (i = 1; i <= preset_count; i++) {
        effective = clean(presets[i])
        key = sprintf("%.8f", effective)
        distance = presets[i] - effective
        if (distance < 0) distance = -distance

        # Multiple presets can collapse to the same clean scale. Keep only the
        # closest label so stepping always moves to a distinct effective value.
        if (!(key in effective_index)) {
          effective_index[key] = ++n
          effective_scales[n] = effective
          scales[n] = presets[i]
          distances[n] = distance
        } else {
          idx = effective_index[key]
          if (distance < distances[idx]) {
            scales[idx] = presets[i]
            distances[idx] = distance
          }
        }
      }

      # Snap to the nearest effective scale first. Hyprland reports floating
      # point values, so exact comparisons can otherwise get stuck.
      best = 1; best_diff = 1e9
      for (i = 1; i <= n; i++) {
        diff = scale - effective_scales[i]; if (diff < 0) diff = -diff
        if (diff < best_diff) { best_diff = diff; best = i }
      }

      if (direction == "next") {
        print scales[(best < n ? best + 1 : n)]
      } else if (direction == "previous") {
        print scales[(best > 1 ? best - 1 : 1)]
      } else {
        print scales[best]
      }
    }'
}

case "${1:-}" in
"")
  focused_monitor_scale | normalize_scale
  ;;
-h | --help)
  usage
  ;;
up)
  monitor_info=$(hyprctl monitors -j | jq -e -c '.[] | select(.focused == true)')
  set_scale "$(echo "$monitor_info" | jq -r '.scale' | scale_from_current next \
    "$(echo "$monitor_info" | jq -r '.width')" "$(echo "$monitor_info" | jq -r '.height')")"
  ;;
down)
  monitor_info=$(hyprctl monitors -j | jq -e -c '.[] | select(.focused == true)')
  set_scale "$(echo "$monitor_info" | jq -r '.scale' | scale_from_current previous \
    "$(echo "$monitor_info" | jq -r '.width')" "$(echo "$monitor_info" | jq -r '.height')")"
  ;;
1 | 1.25 | 1.6 | 2 | 3 | 4)
  set_scale "$1"
  ;;
*)
  if [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]] &&
    awk -v scale="$1" 'BEGIN { exit !(scale >= 1 && scale <= 4) }'; then
    set_scale "$1"
  else
    usage >&2
    exit 1
  fi
  ;;
esac
