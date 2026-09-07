#!/usr/bin/env bash

# omanix:summary=Report the active connection for the shell network panel
# omanix:args=[--verbose]
# omanix:examples=omanix-network-status | omanix-network-status --verbose

# No args: a single tab line "kind<TAB>label<TAB>signal<TAB>freq" where kind is
# wifi|ethernet|disconnected, signal is 0-100 and freq is MHz (read by the
# speedtest panel + network/Model.js parseNetworkStatus). --verbose: one
# key<TAB>value line per field consumed by network/Model.js parseKeyValue:
# iface,type,ip,prefix,gateway,speed,duplex,ssid,signal,freq,bitrate,rx_bytes,
# tx_bytes,router_ping_ms,internet_ping_ms. SSID is emitted raw (iw form,
# possibly \xNN-escaped) — the panel's decodeIwSsid un-escapes it. Ping fields
# carry a single latency in ms, or -1 on timeout so the panel counts loss.
# Always exits 0.

set -uo pipefail

verbose=0
[ "${1:-}" = "--verbose" ] && verbose=1

emit() { [ -n "$2" ] && printf '%s\t%s\n' "$1" "$2"; }

# Primary interface = whichever carries the default route (v4 first, then v6).
iface=$(ip -o -4 route show default 2>/dev/null | awk '{print $5; exit}')
[ -n "$iface" ] || iface=$(ip -o -6 route show default 2>/dev/null | awk '{print $5; exit}')

if [ -z "$iface" ]; then
  # Nothing routable. Short form says so explicitly; verbose stays silent so the
  # panel keeps its last-good sample rather than blanking every row.
  [ "$verbose" = 1 ] || printf 'disconnected\t\t\t\n'
  exit 0
fi

nm_type=$(nmcli -t -g GENERAL.TYPE device show "$iface" 2>/dev/null | head -n1)
case "$nm_type" in
  wifi | 802-11-wireless) kind=wifi ;;
  ethernet | 802-3-ethernet) kind=ethernet ;;
  *) kind="${nm_type:-disconnected}" ;;
esac

ssid="" signal="" freq="" bitrate="" speed="" duplex="" label=""

if [ "$kind" = wifi ]; then
  # SSID/freq/bitrate come from iw (its \xNN SSID escaping is what decodeIwSsid
  # expects); the signal percentage comes from nmcli (already 0-100).
  link=$(iw dev "$iface" link 2>/dev/null)
  ssid=$(printf '%s\n' "$link" | sed -n 's/^\tSSID: //p' | head -n1)
  freq=$(printf '%s\n' "$link" | sed -n 's/^\tfreq: //p' | head -n1)
  bitrate=$(printf '%s\n' "$link" | sed -n 's/.*tx bitrate: \([0-9.]*\).*/\1/p' | head -n1)
  bitrate=${bitrate%.*}
  signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$iface" --rescan no 2>/dev/null \
    | awk -F: '$1=="*"{print $2; exit}')
  label="$ssid"
else
  # Wired link parameters live in sysfs; speed is Mbit/s, duplex full|half.
  speed=$(cat "/sys/class/net/$iface/speed" 2>/dev/null)
  [ "${speed:-0}" -gt 0 ] 2>/dev/null || speed=""
  duplex=$(cat "/sys/class/net/$iface/duplex" 2>/dev/null)
  label=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
  [ -n "$label" ] || label="Ethernet"
fi

if [ "$verbose" != 1 ]; then
  printf '%s\t%s\t%s\t%s\n' "$kind" "$label" "${signal:-}" "${freq:-}"
  exit 0
fi

# ── Extended fields ──────────────────────────────────────────────────────
addr=$(ip -o -4 addr show dev "$iface" scope global 2>/dev/null | awk '{print $4; exit}')
[ -n "$addr" ] || addr=$(ip -o -6 addr show dev "$iface" scope global 2>/dev/null | awk '{print $4; exit}')
ip_addr=${addr%%/*}
prefix=""
[ "$addr" != "$ip_addr" ] && prefix=${addr##*/}

gateway=$(ip -o route show default dev "$iface" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="via"){print $(i+1); exit}}')

rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null)
tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null)

# Probe router + internet latency in parallel so the 1.5s poll stays cheap.
# Backgrounded subshells can't set parent vars, so they write to temp files.
tmp=$(mktemp -d) || tmp=""
ping_to() {
  local target="$1" out="$2"
  local ms=""
  [ -n "$target" ] && ms=$(ping -n -c1 -W1 -I "$iface" "$target" 2>/dev/null \
    | sed -n 's/.*time=\([0-9.]*\).*/\1/p' | head -n1)
  printf '%s' "${ms:--1}" >"$out"
}
router_ms=-1 internet_ms=-1
if [ -n "$tmp" ]; then
  ping_to "$gateway" "$tmp/router" &
  ping_to "1.1.1.1" "$tmp/internet" &
  wait
  router_ms=$(cat "$tmp/router" 2>/dev/null)
  internet_ms=$(cat "$tmp/internet" 2>/dev/null)
  rm -rf "$tmp"
fi

emit iface "$iface"
emit type "$kind"
emit ip "$ip_addr"
emit prefix "$prefix"
emit gateway "$gateway"
emit speed "$speed"
emit duplex "$duplex"
emit ssid "$ssid"
emit signal "$signal"
emit freq "$freq"
emit bitrate "$bitrate"
emit rx_bytes "$rx"
emit tx_bytes "$tx"
emit router_ping_ms "$router_ms"
emit internet_ping_ms "$internet_ms"

exit 0
