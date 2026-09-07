#!/usr/bin/env bash

# omanix:summary=Connect/pair/disconnect/forget a Bluetooth device for the shell panel
# omanix:args=<connect|pair|disconnect|forget> <address>
# omanix:examples=omanix-bluetooth-device connect AA:BB:CC:DD:EE:FF

# Fire-and-forget device actions driven from the shell bluetooth panel (it
# reconciles state from the BlueZ model, not this command's output). "pair"
# trusts + connects on success; "forget" disconnects then removes the pairing.

set -uo pipefail

action="${1:-}"
address="${2:-}"
[ -n "$action" ] && [ -n "$address" ] || {
  echo "Usage: omanix-bluetooth-device <connect|pair|disconnect|forget> <address>" >&2
  exit 2
}

case "$action" in
  connect) bluetoothctl connect "$address" ;;
  disconnect) bluetoothctl disconnect "$address" ;;
  pair)
    bluetoothctl pair "$address" \
      && bluetoothctl trust "$address" \
      && bluetoothctl connect "$address"
    ;;
  forget)
    bluetoothctl disconnect "$address" 2>/dev/null || true
    bluetoothctl remove "$address"
    ;;
  *) echo "Unknown action: $action" >&2; exit 2 ;;
esac
