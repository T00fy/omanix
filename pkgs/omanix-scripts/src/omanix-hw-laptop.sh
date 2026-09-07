#!/usr/bin/env bash

# omanix:summary=Detect whether this machine is a laptop (exit code)

# OMANIX_IS_LAPTOP (set from omanix.hardware.isLaptop) forces the answer when
# the host knows better than the probe. Auto-detection: an ACPI lid switch, or
# a portable DMI chassis type. Exits 0 laptop, 1 desktop.
case "${OMANIX_IS_LAPTOP:-}" in
  true | 1) exit 0 ;;
  false | 0) exit 1 ;;
esac

# ACPI lid button — only laptops expose one.
for lid in /proc/acpi/button/lid/*; do
  [ -e "$lid" ] && exit 0
done

# DMI chassis type: 8 Portable, 9 Laptop, 10 Notebook, 11 Hand Held,
# 14 Sub Notebook, 31 Convertible, 32 Detachable.
chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null) || exit 1
case "$chassis" in
  8 | 9 | 10 | 11 | 14 | 31 | 32) exit 0 ;;
  *) exit 1 ;;
esac
