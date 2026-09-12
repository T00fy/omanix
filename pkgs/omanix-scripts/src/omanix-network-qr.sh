#!/usr/bin/env bash

# omanix:summary=Emit a Wi-Fi QR code (ASCII matrix) for the shell wifiqr panel
# omanix:args=--meta [iface]
# omanix:examples=omanix-network-qr --meta | omanix-network-qr --meta wlan0

# Prints a "meta<TAB><iface><TAB><security><TAB><ssid>" header (SSID last so it
# may contain tabs; security is "nopass" for open, else a WPA token) followed by
# a square matrix of 0/1 module rows, as wifiqr/Model.js parseQrOutput expects.
# Refuses enterprise/802.1X networks (they have no shareable secret) with a
# nonzero exit and a message on stderr. The PSK is fed to qrencode over stdin,
# never argv.

set -uo pipefail

[ "${1:-}" = "--meta" ] || {
  echo "Usage: omanix-network-qr --meta [iface]" >&2
  exit 2
}
iface="${2:-}"

# Default to the connected Wi-Fi interface when none is named.
if [ -z "$iface" ]; then
  iface=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
    | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
fi
[ -n "$iface" ] || { echo "No active Wi-Fi interface" >&2; exit 1; }

con=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
[ -n "$con" ] || { echo "No active connection on $iface" >&2; exit 1; }

keymgmt=$(nmcli -t -g 802-11-wireless-security.key-mgmt connection show "$con" 2>/dev/null | head -n1)
case "$keymgmt" in
  *eap* | *802-1x*)
    echo "Enterprise (802.1X) networks can't be shared as a QR code" >&2
    exit 1
    ;;
esac

ssid=$(nmcli -t -g 802-11-wireless.ssid connection show "$con" 2>/dev/null | head -n1)
[ -n "$ssid" ] || { echo "Could not read SSID" >&2; exit 1; }
psk=$(nmcli -s -g 802-11-wireless-security.psk connection show "$con" 2>/dev/null | head -n1)

if [ -z "$keymgmt" ] || [ "$keymgmt" = "none" ]; then
  security="nopass"
else
  security="WPA"
fi

# Escape the WIFI: payload's reserved characters (\ ; , : ").
esc() { printf '%s' "$1" | sed 's/[\\;,:"]/\\&/g'; }

if [ "$security" = "nopass" ]; then
  payload="WIFI:T:nopass;S:$(esc "$ssid");;"
else
  payload="WIFI:T:WPA;S:$(esc "$ssid");P:$(esc "$psk");H:false;;"
fi

printf 'meta\t%s\t%s\t%s\n' "$iface" "$security" "$ssid"

# ASCII render (margin 0) → collapse each 2-char module cell to one 0/1 bit;
# any non-space glyph is a dark module. Empty trailing lines are dropped by the
# panel's parser, and a non-square result is rejected there too.
printf '%s' "$payload" | qrencode -t ASCII -m 0 2>/dev/null | awk '{
  line = ""
  for (i = 1; i <= length($0); i += 2) {
    c = substr($0, i, 1)
    line = line (c == " " ? "0" : "1")
  }
  if (line != "") print line
}'
