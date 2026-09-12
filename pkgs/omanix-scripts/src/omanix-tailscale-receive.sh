#!/usr/bin/env bash

# omanix:summary=Taildrop receiver: save incoming files to ~/Downloads and notify
# omanix:group=network
# omanix:args=[--once]
# omanix:examples=omanix-tailscale-receive --once

set -uo pipefail

ONCE=0
[[ "${1:-}" == "--once" ]] && ONCE=1

DOWNLOADS="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
# Staging lives under DOWNLOADS so the final placement is a same-filesystem
# hard link (link(2)) — the atomic, collision-safe claim below.
STAGING="$DOWNLOADS/.omanix-taildrop"
mkdir -p "$STAGING"

# Claim a final name in DOWNLOADS for a staged file via ln (link(2)): ln fails
# if the target already exists, so on collision we derive "name (N).ext" and
# retry. No partial-file races, no clobbering. Prints the claimed path.
claim() {
  local src="$1" base stem ext target n
  base="$(basename "$src")"
  target="$DOWNLOADS/$base"
  if ln "$src" "$target" 2>/dev/null; then
    printf '%s\n' "$target"
    return 0
  fi
  if [[ "$base" == *.* && "$base" != .* ]]; then
    stem="${base%.*}"
    ext=".${base##*.}"
  else
    stem="$base"
    ext=""
  fi
  n=1
  while ((n <= 9999)); do
    target="$DOWNLOADS/$stem ($n)$ext"
    if ln "$src" "$target" 2>/dev/null; then
      printf '%s\n' "$target"
      return 0
    fi
    n=$((n + 1))
  done
  return 1
}

# Notify for one received file: image preview for images, best-effort
# click-to-open. Backgrounded so waiting on the action never stalls the loop
# (a daemon without action support just returns empty and nothing opens).
notify_open() {
  local f="$1" name mime
  name="$(basename "$f")"
  mime="$(file --mime-type -b "$f" 2>/dev/null || true)"
  local args=(-A "open=Open" "Taildrop" "Received $name")
  [[ "$mime" == image/* ]] && args=(-i "$f" "${args[@]}")
  (
    action="$(notify-send "${args[@]}" 2>/dev/null || true)"
    [[ "$action" == "open" ]] && xdg-open "$f" >/dev/null 2>&1
  ) &
}

process_staging() {
  local f final
  shopt -s nullglob dotglob
  for f in "$STAGING"/*; do
    [[ -f "$f" ]] || continue
    if final="$(claim "$f")"; then
      rm -f "$f"
      notify_open "$final"
    fi
  done
  shopt -u nullglob dotglob
}

# Block until at least one file arrives, download all waiting files into
# staging, then place + notify.
run_once() {
  tailscale file get --wait --conflict=rename "$STAGING" || return 1
  process_staging
}

if ((ONCE)); then
  run_once
  exit $?
fi

# Long-running receiver: on a transient failure (daemon down, logged out) back
# off and retry rather than exiting so systemd doesn't hot-loop restarts.
while true; do
  run_once || sleep 5
done
