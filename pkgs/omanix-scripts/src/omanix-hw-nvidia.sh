#!/usr/bin/env bash

# omanix:summary=Detect an NVIDIA GPU (exit code)

# Reads cached PCI sysfs (vendor 0x10de, class 0x03* = display controller)
# rather than lspci, so it never wakes a runtime-suspended GPU. Exits 0 when an
# NVIDIA display device is present, 1 otherwise.
for dev in /sys/bus/pci/devices/*; do
  [ -e "$dev/vendor" ] || continue
  vendor=$(cat "$dev/vendor" 2>/dev/null) || continue
  [ "$vendor" = "0x10de" ] || continue
  class=$(cat "$dev/class" 2>/dev/null) || continue
  case "$class" in
    0x03*) exit 0 ;;
  esac
done

exit 1
