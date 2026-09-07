#!/usr/bin/env bash

# omanix:summary=Live down/up throughput (Mbps per line) for the shell speedtest panel
# omanix:args=<down|up>
# omanix:examples=omanix-network-speedtest down | omanix-network-speedtest up

# Streams one throughput sample (Mbps, float) per line for the requested phase
# until killed by the panel (which caps each phase). Runs parallel curl workers
# against Netflix fast.com endpoints and reports the delta of the active
# interface's rx/tx byte counters each interval — so any DSP-free physical rate
# is captured regardless of the transfer library. Errors go to stderr.

set -uo pipefail

phase="${1:-}"
case "$phase" in
  down | up) ;;
  *) echo "Usage: omanix-network-speedtest <down|up>" >&2; exit 2 ;;
esac

iface=$(ip -o route show default 2>/dev/null | awk '{print $5; exit}')
[ -n "$iface" ] || { echo "No default route" >&2; exit 1; }

# Public fast.com measurement token (embedded in fast.com's own client). Used
# only to discover nearby download/upload target URLs.
token="YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm"
urls=$(curl -s --max-time 5 \
  "https://api.fast.com/netflix/speedtest/v2?https=true&token=$token&urlCount=5" 2>/dev/null \
  | grep -o '"url":"[^"]*"' | sed 's/"url":"//; s/"$//')
[ -n "$urls" ] || { echo "Could not reach the speed test servers" >&2; exit 1; }

stat=rx_bytes
[ "$phase" = up ] && stat=tx_bytes
read_bytes() { cat "/sys/class/net/$iface/statistics/$stat" 2>/dev/null; }

pids=()
while IFS= read -r u; do
  [ -n "$u" ] || continue
  if [ "$phase" = down ]; then
    (while :; do curl -s -o /dev/null --max-time 10 "$u" || true; done) &
  else
    (while :; do
      head -c 26214400 /dev/zero \
        | curl -s -o /dev/null --max-time 10 -X POST --data-binary @- "$u" || true
    done) &
  fi
  pids+=("$!")
done <<<"$urls"

cleanup() { [ "${#pids[@]}" -gt 0 ] && kill "${pids[@]}" 2>/dev/null || true; }
trap cleanup EXIT

interval=0.3
prev=$(read_bytes); prev=${prev:-0}
end=$((SECONDS + 8))
while [ "$SECONDS" -lt "$end" ]; do
  sleep "$interval"
  now=$(read_bytes); now=${now:-$prev}
  awk -v d="$((now - prev))" -v t="$interval" 'BEGIN { printf "%.2f\n", (d * 8) / (t * 1000000) }'
  prev=$now
done
