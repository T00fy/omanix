#!/usr/bin/env bash

# omanix:summary=Detect an unconfigured USB fingerprint reader (exit code)

# Probes /sys/bus/usb/devices directly (works before fprintd/libfprint exist)
# for a reader from a known-vendor allowlist that has no kernel driver bound
# yet — i.e. one that still needs enabling. A reader already driven is left
# alone. Exits 0 when a candidate is found, 1 otherwise.
#
# Vendor allowlist: 06cb Synaptics/Validity, 138a Validity, 27c6 Goodix,
# 04f3 Elan, 08ff AuthenTec, 147e Upek, 1c7a LighTuning, 0483 STMicro.
allow=" 06cb 138a 27c6 04f3 08ff 147e 1c7a 0483 "

for dev in /sys/bus/usb/devices/*; do
  [ -e "$dev/idVendor" ] || continue
  vendor=$(cat "$dev/idVendor" 2>/dev/null) || continue
  case "$allow" in
    *" $vendor "*) ;;
    *) continue ;;
  esac

  # Skip when any interface already has a driver bound.
  bound=false
  for iface in "$dev":*; do
    [ -e "$iface/driver" ] && bound=true && break
  done
  $bound && continue

  exit 0
done

exit 1
