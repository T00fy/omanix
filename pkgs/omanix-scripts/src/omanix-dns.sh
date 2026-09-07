#!/usr/bin/env bash

# omanix:summary=Show or set the DNS provider on the active connection
# omanix:args=[DHCP|Cloudflare|Google|Custom]
# omanix:examples=omanix-dns | omanix-dns Cloudflare | omanix-dns Custom

# No args: print the current provider name (DHCP|Cloudflare|Google|Custom) the
# shell network panel and menu read. With a provider: pin its resolvers on the
# active connection and reapply live. "Custom" prompts for servers (run in a
# terminal). Exit 0 on success.

set -uo pipefail

# Resolve the active connection: prefer the one on the default-route interface,
# else the first active profile.
iface=$(ip -o route show default 2>/dev/null | awk '{print $5; exit}')
con=""
[ -n "$iface" ] && con=$(nmcli -t -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1)
[ -n "$con" ] || con=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n1)
[ -n "$con" ] || { echo "No active connection" >&2; exit 1; }

reapply() {
  # Apply changed settings without tearing the link down when possible.
  if [ -n "$iface" ] && nmcli device reapply "$iface" >/dev/null 2>&1; then
    return 0
  fi
  nmcli connection up "$con" >/dev/null 2>&1
}

provider="${1:-}"

if [ -z "$provider" ]; then
  dns=$(nmcli -t -g ipv4.dns connection show "$con" 2>/dev/null | head -n1)
  case "$dns" in
    "") echo "DHCP" ;;
    *1.1.1.1* | *1.0.0.1*) echo "Cloudflare" ;;
    *8.8.8.8* | *8.8.4.4*) echo "Google" ;;
    *) echo "Custom" ;;
  esac
  exit 0
fi

set_dns() {
  # $1 = ipv4 servers (space-separated, "" = DHCP), $2 = ipv6 servers
  local v4="$1" v6="$2"
  if [ -z "$v4" ]; then
    nmcli connection modify "$con" \
      ipv4.dns "" ipv4.ignore-auto-dns no \
      ipv6.dns "" ipv6.ignore-auto-dns no >/dev/null 2>&1
  else
    nmcli connection modify "$con" \
      ipv4.dns "$v4" ipv4.ignore-auto-dns yes \
      ipv6.dns "$v6" ipv6.ignore-auto-dns yes >/dev/null 2>&1
  fi
}

case "$provider" in
  DHCP) set_dns "" "" ;;
  Cloudflare) set_dns "1.1.1.1 1.0.0.1" "2606:4700:4700::1111 2606:4700:4700::1001" ;;
  Google) set_dns "8.8.8.8 8.8.4.4" "2001:4860:4860::8888 2001:4860:4860::8844" ;;
  Custom)
    read -rp "DNS servers (space-separated IPv4/IPv6): " servers
    [ -n "$servers" ] || { echo "No servers entered" >&2; exit 1; }
    v4="" v6=""
    for s in $servers; do
      case "$s" in
        *:*) v6="$v6 $s" ;;
        *) v4="$v4 $s" ;;
      esac
    done
    set_dns "${v4# }" "${v6# }"
    ;;
  *) echo "Unknown provider: $provider" >&2; exit 2 ;;
esac || { echo "Failed to set DNS" >&2; exit 1; }

reapply
