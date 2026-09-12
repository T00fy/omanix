#!/usr/bin/env bash

# omanix:summary=Print the most likely backlight device for brightness control

# Prints one backlight device name (as found under /sys/class/backlight) in
# preference order gmux -> amdgpu -> intel -> acpi_video, so callers control the
# right panel on hybrid/Mac hardware. The T2 Mac Touch Bar backlight is skipped
# — it is never the main display. Exits 0 when one is printed, 1 when none.
prefer() {
  for dev in /sys/class/backlight/"$1"*; do
    [ -e "$dev" ] || continue
    name=${dev##*/}
    case "$name" in
      *touchbar*) continue ;;
    esac
    echo "$name"
    return 0
  done
  return 1
}

prefer gmux_backlight && exit 0
prefer amdgpu_bl && exit 0
prefer intel_backlight && exit 0
prefer acpi_video && exit 0

# Fall back to whatever is present (still excluding the Touch Bar).
for dev in /sys/class/backlight/*; do
  [ -e "$dev" ] || continue
  name=${dev##*/}
  case "$name" in
    *touchbar*) continue ;;
  esac
  echo "$name"
  exit 0
done

exit 1
