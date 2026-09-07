#!/usr/bin/env bash

# omanix:summary=Report battery status for the shell power panel
# omanix:args=[--shell]

# Emits the fields the Quickshell power panel reads (percentage, size, cycles,
# threshold, time, rate) as tab-separated key<TAB>value lines when called with
# --shell. Values are pre-formatted display strings. No battery -> no output
# (the panel keeps its last-known-good / stays hidden). Always exits 0.
#
# Sources /sys/class/power_supply/BAT*: energy_* (µWh/µW) when present, else
# charge_* (µAh/µA) scaled by voltage. time/rate are derived from the live
# power draw and charge direction.

mode="human"
[ "${1:-}" = "--shell" ] && mode="shell"

bat=""
for dir in /sys/class/power_supply/BAT* /sys/class/power_supply/CMB*; do
  [ -e "$dir/type" ] || continue
  [ "$(cat "$dir/type" 2>/dev/null)" = "Battery" ] && bat="$dir" && break
done
[ -n "$bat" ] || exit 0

rd() { cat "$bat/$1" 2>/dev/null; }

capacity=$(rd capacity)
cycles=$(rd cycle_count)
status=$(rd status)
threshold=$(rd charge_control_end_threshold)

# Energy (µWh) / power (µW) preferred; fall back to charge (µAh) / current (µA)
# scaled by voltage (µV) so the arithmetic is always in energy units.
energy_now=$(rd energy_now)
energy_full=$(rd energy_full)
energy_full_design=$(rd energy_full_design)
power_now=$(rd power_now)
charge_now=$(rd charge_now)
charge_full=$(rd charge_full)
charge_full_design=$(rd charge_full_design)
current_now=$(rd current_now)
voltage_now=$(rd voltage_now)

out=$(gawk \
  -v capacity="${capacity:-}" \
  -v cycles="${cycles:-}" \
  -v status="${status:-}" \
  -v threshold="${threshold:-}" \
  -v e_now="${energy_now:-}" \
  -v e_full="${energy_full:-}" \
  -v e_design="${energy_full_design:-}" \
  -v p_now="${power_now:-}" \
  -v c_now="${charge_now:-}" \
  -v c_full="${charge_full:-}" \
  -v c_design="${charge_full_design:-}" \
  -v i_now="${current_now:-}" \
  -v v_now="${voltage_now:-}" '
  function emit(k, v) { if (v != "") printf "%s\t%s\n", k, v }
  function fmt_time(hours,   h, m) {
    if (hours <= 0) return ""
    h = int(hours); m = int((hours - h) * 60 + 0.5)
    if (m == 60) { h += 1; m = 0 }
    if (h > 0) return h "h " m "m"
    return m "m"
  }
  BEGIN {
    v = (v_now != "") ? v_now / 1000000.0 : 0   # volts

    # Normalize to Wh / W regardless of energy- vs charge-reporting battery.
    if (e_now != "")   { now = e_now / 1000000.0 } else if (c_now != "" && v > 0)   { now = c_now / 1000000.0 * v } else now = ""
    if (e_full != "")  { full = e_full / 1000000.0 } else if (c_full != "" && v > 0) { full = c_full / 1000000.0 * v } else full = ""
    if (e_design != ""){ design = e_design / 1000000.0 } else if (c_design != "" && v > 0) { design = c_design / 1000000.0 * v } else design = ""
    if (p_now != "")   { rate = p_now / 1000000.0 } else if (i_now != "" && v > 0)   { rate = i_now / 1000000.0 * v } else rate = ""

    if (capacity != "") emit("percentage", capacity "%")
    if (design != "")   emit("size", sprintf("%.1f Wh", design))
    emit("cycles", cycles)
    if (threshold != "") emit("threshold", threshold "%")

    if (rate != "" && rate > 0.05) emit("rate", sprintf("%.1f W", rate))

    if (rate != "" && rate > 0.05 && now != "") {
      if (status == "Discharging") emit("time", fmt_time(now / rate))
      else if (status == "Charging" && full != "") emit("time", fmt_time((full - now) / rate))
    }
  }
')

if [ "$mode" = "shell" ]; then
  printf '%s' "$out"
  [ -n "$out" ] && printf '\n'
else
  # Human summary: percentage + status on one line.
  pct=$(printf '%s\n' "$out" | gawk -F'\t' '$1=="percentage"{print $2}')
  printf '%s %s\n' "${pct:-?}" "${status:-Unknown}"
fi

exit 0
