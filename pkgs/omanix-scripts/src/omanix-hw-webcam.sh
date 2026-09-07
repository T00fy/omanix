#!/usr/bin/env bash

# omanix:summary=Detect at least one usable webcam (exit code)

# Gates webcam features. Delegates to omanix-capture-webcam-list when present;
# otherwise falls back to a V4L2 sysfs presence check. Exits 0 when a webcam is
# found, 1 otherwise.
if command -v omanix-capture-webcam-list >/dev/null 2>&1; then
  [ -n "$(omanix-capture-webcam-list 2>/dev/null)" ] && exit 0
  exit 1
fi

# A capture-capable V4L2 node is enough of a signal for the presence check.
for node in /sys/class/video4linux/video*; do
  [ -e "$node" ] && exit 0
done

exit 1
