#!/usr/bin/env bash

# omanix:summary=Toggle the Bluetooth adapter for the shell panel
# omanix:args=<on|off>
# omanix:examples=omanix-bluetooth-power on | omanix-bluetooth-power off

# Moves the rfkill soft block (not just BlueZ "Powered") so systemd-rfkill
# persists the state across reboots, then sets adapter power to match. The panel
# passes an explicit direction and re-reads adapter state afterward.

set -uo pipefail

case "${1:-}" in
  on)
    rfkill unblock bluetooth 2>/dev/null || true
    bluetoothctl power on
    ;;
  off)
    bluetoothctl power off 2>/dev/null || true
    rfkill block bluetooth
    ;;
  *) echo "Usage: omanix-bluetooth-power <on|off>" >&2; exit 2 ;;
esac
