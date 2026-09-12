#!/bin/bash

# omanix:summary=Run the Omanix screensaver using random ttfx effects (runs inside the screensaver terminal).
# omanix:args=
# omanix:examples=omanix-screensaver

# Runs inside a fullscreen org.omanix.screensaver terminal spawned by
# omanix-launch-screensaver. Not meant to be run standalone.

# Guard: this must run inside a screensaver terminal, where stdin is the
# terminal's pty. If it is invoked directly with no controlling terminal (e.g.
# a stale menu whose action still points here instead of at
# omanix-launch-screensaver), bail out cleanly -- otherwise the ttfx loop below
# spins invisibly against a nonexistent tty.
if [[ ! -t 0 ]]; then
  echo "omanix-screensaver runs inside a screensaver terminal; use omanix-launch-screensaver." >&2
  exit 0
fi

screensaver_in_focus() {
  hyprctl activewindow -j | jq -e '.class == "org.omanix.screensaver"' >/dev/null 2>&1
}

# A terminal only emits bytes on pointer *movement* when mouse-motion reporting
# is on, so without this any mouse move goes unnoticed. ?1003h = report all
# motion, ?1006h = SGR encoding. ttfx may reset it on startup, so it is
# re-asserted each frame loop below.
mouse_report_on() { printf '\033[?1003h\033[?1006h'; }
mouse_report_off() { printf '\033[?1003l\033[?1006l' 2>/dev/null || true; }

exit_screensaver() {
  mouse_report_off
  hyprctl eval 'hl.config({ cursor = { invisible = false } })' &>/dev/null || hyprctl keyword cursor:invisible false &>/dev/null || true
  pkill -x ttfx 2>/dev/null || true
  pkill -f '[o]rg.omanix.screensaver' 2>/dev/null || true
  exit 0
}

# Exit the screensaver on signals and on input from keyboard and mouse.
trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

printf '\033]11;rgb:00/00/00\007' # Set background color to black
hyprctl eval 'hl.config({ cursor = { invisible = true } })' &>/dev/null || hyprctl keyword cursor:invisible true &>/dev/null
mouse_report_on

tty=$(tty 2>/dev/null)

# Terminals allocate the pty at the default 80x24 and only resize it once the
# compositor has told the window how big it is. ttfx measures the terminal once,
# at startup, so starting it before the resize lands sizes an 80x24 canvas and
# paints it into the corner of a fullscreen window.
wait_for_terminal_resize() {
  local deadline=$((SECONDS + 2))
  while ((SECONDS < deadline)) && [[ $(stty size 2>/dev/null) == "24 80" ]]; do
    sleep 0.02
  done
}

wait_for_terminal_resize

logo_args=()
if [[ -n "${OMANIX_SCREENSAVER_LOGO:-}" ]]; then
  logo_args=(-i "$OMANIX_SCREENSAVER_LOGO")
fi

while true; do
  # ttfx reads its text from -i, never stdin. Give it /dev/null anyway so it
  # cannot touch, flush, or consume the terminal's input -- otherwise it races
  # the read below and swallows keypresses, leaving the screensaver dismissable
  # only by the odd key that slips through.
  ttfx "${logo_args[@]}" \
    --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas \
    --anchor-canvas c --anchor-text c --random-effect --no-eol --no-restore-cursor </dev/null &

  mouse_report_on # re-assert in case ttfx cleared it on startup

  while pgrep -t "${tty#/dev/}" -x ttfx >/dev/null; do
    if read -r -n1 -t 1 || ! screensaver_in_focus; then
      exit_screensaver
    fi
  done
done
