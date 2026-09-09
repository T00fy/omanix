#!/usr/bin/env bash

# omanix:summary=Read or set the default coding agent, then launch it
# omanix:args=[<agent-id>]
# omanix:examples=omanix-default-agent | omanix-default-agent claude

set -euo pipefail

DEFAULT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/omanix/defaults/agent"

# No args: print the current default (empty when unset), exit 0.
if (($# == 0)); then
  [[ -f $DEFAULT_FILE ]] && cat "$DEFAULT_FILE"
  exit 0
fi

id="$1"

# Validate against omanix-agent's canonical map (single source of truth).
if ! omanix-agent --is-agent "$id"; then
  echo "omanix-default-agent: unknown agent '$id'." >&2
  exit 1
fi

# Setting the default just writes the file — no install (D3). This is an
# ephemeral overlay: a rebuild reverts to omanix.apps.ai.defaultAgent if declared.
mkdir -p "$(dirname "$DEFAULT_FILE")"
printf '%s\n' "$id" >"$DEFAULT_FILE"

# Launch the freshly-selected agent (presence check / guidance lives there).
exec omanix-agent
