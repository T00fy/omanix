#!/usr/bin/env bash

# omanix:summary=Report host/kernel/uptime/cpu/memory/disk for the shell power panel

# Emits tab-separated key<TAB>value lines (host, kernel, uptime, cpu, memory,
# disk) as pre-formatted display strings for the Quickshell power panel. The
# panel tolerates missing keys and empty output; always exits 0.

emit() { [ -n "$2" ] && printf '%s\t%s\n' "$1" "$2"; }

# Host / kernel.
host=$(cat /etc/hostname 2>/dev/null || uname -n 2>/dev/null)
emit host "$host"
emit kernel "$(uname -r 2>/dev/null)"

# Uptime from /proc/uptime -> "Nd Nh Nm".
secs=$(gawk '{print int($1)}' /proc/uptime 2>/dev/null)
if [ -n "$secs" ]; then
  emit uptime "$(gawk -v s="$secs" 'BEGIN {
    d = int(s / 86400); s %= 86400
    h = int(s / 3600);  s %= 3600
    m = int(s / 60)
    if (d > 0)      printf "%dd %dh %dm", d, h, m
    else if (h > 0) printf "%dh %dm", h, m
    else            printf "%dm", m
  }')"
fi

# CPU usage over a short sample of /proc/stat.
read_cpu() { gawk '/^cpu /{ t=0; for (i=2;i<=NF;i++) t+=$i; print t, $5 }' /proc/stat 2>/dev/null; }
read -r t1 i1 <<<"$(read_cpu)"
sleep 0.25
read -r t2 i2 <<<"$(read_cpu)"
if [ -n "$t1" ] && [ -n "$t2" ] && [ "$t2" != "$t1" ]; then
  emit cpu "$(gawk -v t1="$t1" -v i1="$i1" -v t2="$t2" -v i2="$i2" \
    'BEGIN { u = 100 * (1 - (i2 - i1) / (t2 - t1)); if (u < 0) u = 0; printf "%.0f%%", u }')"
fi

# Memory used / total from /proc/meminfo (MemAvailable is the honest "free").
emit memory "$(gawk '
  /^MemTotal:/     { total = $2 }
  /^MemAvailable:/ { avail = $2 }
  END {
    if (total > 0) {
      used = (total - avail) / 1048576.0   # kB -> GiB
      tot  = total / 1048576.0
      printf "%.1f / %.1f GiB", used, tot
    }
  }' /proc/meminfo 2>/dev/null)"

# Root filesystem usage.
emit disk "$(df -h --output=used,size / 2>/dev/null | gawk 'NR==2 { printf "%s / %s", $1, $2 }')"

exit 0
