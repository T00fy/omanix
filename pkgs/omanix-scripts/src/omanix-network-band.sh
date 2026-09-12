#!/usr/bin/env bash

# omanix:summary=Show or pin the active Wi-Fi band for the shell network panel
# omanix:args=[2.4|5|6|auto]
# omanix:examples=omanix-network-band | omanix-network-band 5 | omanix-network-band auto

# No args: key<TAB>value status (band = the band in use, selected = the pinned
# choice or "auto", available = space-separated bands seen in the cached scan),
# read by network/Model.js parseBandStatus. With a band token: pin it on the
# active connection via NetworkManager 802-11-wireless.band and reassociate.
# Exit 0 once reconnected; on failure the previous band is restored and the exit
# is nonzero so the panel leaves the pill selection alone. No connected station
# emits nothing (the panel keeps its last-good list through a reconnect).

set -uo pipefail

# NetworkManager's connection.band only distinguishes 2.4GHz (bg) from 5/6GHz
# (a); 6GHz shares the "a" token, so pinning 6 falls back to the 5/6 radio.
tok_for() {
  case "$1" in
    2.4) echo bg ;;
    5 | 6) echo a ;;
    auto | "") echo "" ;;
    *) echo "" ;;
  esac
}

freq_to_band() {
  awk -v f="$1" 'BEGIN{
    if (f>=2400 && f<2500) print "2.4";
    else if (f>=4900 && f<5925) print "5";
    else if (f>=5925 && f<7125) print "6";
  }'
}

wifi_iface=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
  | awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')
[ -n "$wifi_iface" ] || exit 0

con=$(nmcli -t -g GENERAL.CONNECTION device show "$wifi_iface" 2>/dev/null | head -n1)
[ -n "$con" ] || exit 0

action="${1:-}"

if [ -z "$action" ]; then
  # ── Query ──────────────────────────────────────────────────────────────
  cur_freq=$(iw dev "$wifi_iface" link 2>/dev/null | sed -n 's/^\tfreq: //p' | head -n1)
  band=$(freq_to_band "${cur_freq:-0}")

  sel_tok=$(nmcli -t -g 802-11-wireless.band connection show "$con" 2>/dev/null | head -n1)
  case "$sel_tok" in
    bg) selected="2.4" ;;
    a) selected="5" ;;
    *) selected="auto" ;;
  esac

  # Available bands = the distinct bands present in the cached AP list.
  available=$(nmcli -t -f FREQ device wifi list ifname "$wifi_iface" --rescan no 2>/dev/null \
    | awk '{gsub(/[^0-9]/,"",$0); if($0!="") print $0}' \
    | while read -r f; do freq_to_band "$f"; done \
    | sort -u | tr '\n' ' ' | sed 's/ *$//')

  printf 'band\t%s\n' "$band"
  printf 'selected\t%s\n' "$selected"
  printf 'available\t%s\n' "$available"
  exit 0
fi

# ── Pin ────────────────────────────────────────────────────────────────────
new_tok=$(tok_for "$action")
old_tok=$(nmcli -t -g 802-11-wireless.band connection show "$con" 2>/dev/null | head -n1)

nmcli connection modify "$con" 802-11-wireless.band "$new_tok" >/dev/null 2>&1 || exit 1

if nmcli connection up "$con" >/dev/null 2>&1; then
  exit 0
fi

# Reassociation failed on the requested band: restore the prior pin so the link
# comes back where it was, and report failure.
nmcli connection modify "$con" 802-11-wireless.band "$old_tok" >/dev/null 2>&1
nmcli connection up "$con" >/dev/null 2>&1
exit 1
