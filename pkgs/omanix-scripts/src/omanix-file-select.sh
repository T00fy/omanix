#!/usr/bin/env bash

# omanix:summary=Pick file(s) in a floating terminal, print selected paths to stdout
# omanix:group=util
# omanix:examples=omanix-file-select

set -uo pipefail

# Callers (e.g. the shell tailscale panel) invoke pickers without a controlling
# terminal, so run fzf inside a floating omanix-term and hand the selection back
# through a temp file. The org.omanix.terminal class already floats+centers via
# the floating-window rule in desktop/hyprland/rules.nix.
sel="$(mktemp)"
trap 'rm -f "$sel"' EXIT

start_dir="${1:-$HOME}"

omanix-term --class="org.omanix.terminal" -- \
  sh -c 'cd "$2" 2>/dev/null || cd "$HOME"; find "$PWD" -type f 2>/dev/null | fzf --multi --prompt "Select file(s) > " >"$1"' \
  _ "$sel" "$start_dir"

# Empty (cancelled) is a clean no-op — the caller decides what that means.
cat "$sel"
