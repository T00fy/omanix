#!/usr/bin/env bash

# omanix:summary=Detect whether the laptop lid is closed (exit code)

# Reads the live ACPI lid state — flips at runtime as the lid opens/closes.
# Exits 0 closed, 1 open (or no lid present). The shell wraps this as
# `omanix-hw-laptop-closed && echo closed || echo open` and reads exit only.
for state in /proc/acpi/button/lid/*/state; do
  [ -e "$state" ] || continue
  grep -qi closed "$state" 2>/dev/null && exit 0
done

exit 1
