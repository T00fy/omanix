#!/bin/bash

# omanix:summary=Sync current Omanix theme into a running tmux
# omanix:hidden=true

# Live-retint a running tmux server to the current palette (colors, cursor,
# COLORFGBG, per-pane OSC). Ephemeral — the declared theme's baseline is set by
# apps/tmux.nix on rebuild. No-ops cleanly when no tmux server is running.
#
# Upstream also synced gum_env.lua's hl.env(KEY,VAL) pairs into tmux
# environment; omanix never generates gum_env.lua, so that step is dropped.

CURRENT_THEME_PATH="$HOME/.local/state/omanix/current/theme"
COLORS_TOML="$CURRENT_THEME_PATH/colors.toml"

if ! tmux list-sessions >/dev/null 2>&1; then
  exit 0
fi

set_tmux_environment() {
  local key="$1"
  local value="$2"
  local session

  tmux set-environment -g "$key" "$value" 2>/dev/null || return 0

  while IFS= read -r session; do
    [[ -n $session ]] || continue
    tmux set-environment -t "$session" "$key" "$value" 2>/dev/null || true
  done < <(tmux list-sessions -F "#{session_id}" 2>/dev/null)
}

sync_colorfgbg() {
  local colorfgbg="15;0"

  # theme_color resolves mode from colors.toml, a legacy light.mode file, or
  # background luminance, so a bare light check covers all theme styles.
  if [[ $(theme_color mode) == "light" ]]; then
    colorfgbg="0;15"
  fi

  set_tmux_environment COLORFGBG "$colorfgbg"
}

theme_osc_sequences() {
  omanix-theme-osc "$COLORS_TOML"
}

theme_color() {
  omanix-theme-color --file "$COLORS_TOML" "$@"
}

sync_tmux_window_style() {
  local background foreground cursor

  [[ -f $COLORS_TOML ]] || return

  foreground=$(theme_color foreground)
  background=$(theme_color background)
  cursor=$(theme_color cursor)

  [[ -n $foreground && -n $background ]] || return

  tmux set-option -g window-style "fg=$foreground,bg=$background" 2>/dev/null || true
  tmux set-option -g window-active-style "fg=$foreground,bg=$background" 2>/dev/null || true

  # Apps like nvim clear the per-pane cursor colour with OSC 112. Without a
  # global fallback, tmux then resets the outer terminal's cursor, which in
  # terminals that can't reload their config (foot) restores the colour from
  # whatever theme was active when the terminal launched.
  if [[ -n $cursor ]]; then
    tmux set-option -g cursor-colour "$cursor" 2>/dev/null || true
  fi
}

sync_tmux_pane_colors() {
  local pane_tty theme_osc

  [[ -f $COLORS_TOML ]] || return

  theme_osc=$(theme_osc_sequences)
  [[ -n $theme_osc ]] || return

  while IFS= read -r pane_tty; do
    [[ $pane_tty == /dev/pts/* ]] || continue
    printf '%b' "$theme_osc" >"$pane_tty" 2>/dev/null || true
  done < <(tmux list-panes -a -F "#{pane_tty}" 2>/dev/null | sort -u)
}

signal_tmux_panes() {
  local pane_tty tpgid

  while IFS= read -r pane_tty; do
    [[ $pane_tty == /dev/pts/* ]] || continue
    tpgid=$(ps -o tpgid= -t "${pane_tty#/dev/}" 2>/dev/null | awk 'NF && $1 > 0 { print $1; exit }')
    [[ -n $tpgid ]] || continue
    kill -WINCH "-$tpgid" 2>/dev/null || true
  done < <(tmux list-panes -a -F "#{pane_tty}" 2>/dev/null | sort -u)
}

refresh_tmux_clients() {
  local client

  while IFS= read -r client; do
    [[ -n $client ]] || continue
    tmux refresh-client -t "$client" 2>/dev/null || true
  done < <(tmux list-clients -F "#{client_name}" 2>/dev/null)
}

sync_colorfgbg
sync_tmux_window_style
sync_tmux_pane_colors
signal_tmux_panes
refresh_tmux_clients
