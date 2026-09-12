#!/usr/bin/env bash

# omanix:summary=Reveal the active Wi-Fi password for the shell wifiqr panel
# omanix:args=<iface>
# omanix:examples=omanix-network-password wlan0

# Prints the PSK of the connection active on <iface> as a single line. Exits
# nonzero (no output) when there is no connection or no stored passphrase.

set -uo pipefail

iface="${1:-}"
[ -n "$iface" ] || { echo "Usage: omanix-network-password <iface>" >&2; exit 2; }

con=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
[ -n "$con" ] || exit 1

psk=$(nmcli -s -g 802-11-wireless-security.psk connection show "$con" 2>/dev/null | head -n1)
[ -n "$psk" ] || exit 1

printf '%s\n' "$psk"
