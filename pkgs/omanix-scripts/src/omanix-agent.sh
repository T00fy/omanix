#!/usr/bin/env bash

# omanix:summary=Launch the default coding-agent CLI in auto-approve mode
# omanix:args=[--inline] [--pick] [--prompt "<text>"]
# omanix:examples=omanix-agent | omanix-agent --inline | omanix-agent --pick | omanix-agent --prompt "fix the build"

set -euo pipefail

DEFAULT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/omanix/defaults/agent"
APP_ID="org.omanix.agent"

# Canonical agent map — the single source of truth (omanix-default-agent
# validates against it via --is-agent). Scoped to what omanix packages via the
# llm-agents input (omanix.apps.ai.*); keep in lockstep with the omanix-menu.jsonc
# picker and the omanix.apps.ai.defaultAgent enum.
#
# Auto-approve flags are each agent's "don't stop to ask" invocation; edit them
# here if an agent changes its CLI. There is no per-user install step — an agent
# is available iff its binary is on PATH (its omanix.apps.ai.* option is enabled).
agent_bin() {
  case "$1" in
  claude) echo "claude" ;;
  opencode) echo "opencode" ;;
  *) return 1 ;;
  esac
}

agent_flags() {
  case "$1" in
  claude) echo "--permission-mode auto" ;;
  opencode) echo "--auto" ;;
  *) return 1 ;;
  esac
}

# The omanix.apps.ai.* option that installs the agent, surfaced when its binary
# is missing (guide to declarative config, never install).
agent_option() {
  case "$1" in
  claude) echo "omanix.apps.ai.claudeCode.enable" ;;
  opencode) echo "omanix.apps.ai.openCode.enable" ;;
  *) return 1 ;;
  esac
}

is_agent() { agent_bin "$1" >/dev/null 2>&1; }

# No ~/Work directory in omanix, so the upstream `cd ~/Work` before launch is dropped.

inline=false
pick=false
prompt=""

while (($#)); do
  case "$1" in
  --is-agent)
    # Hidden: exit 0/1 if $2 is a known agent id (used by omanix-default-agent).
    is_agent "${2:-}"
    exit $?
    ;;
  --inline) inline=true; shift ;;
  --pick) pick=true; shift ;;
  --prompt) prompt="${2:-}"; shift 2 ;;
  -h | --help)
    echo "Usage: omanix-agent [--inline] [--pick] [--prompt \"<text>\"]"
    exit 0
    ;;
  *)
    echo "omanix-agent: unknown argument: $1" >&2
    exit 1
    ;;
  esac
done

if $pick; then
  exec omanix-menu show setup.defaults.agent
fi

default=""
[[ -f $DEFAULT_FILE ]] && default="$(<"$DEFAULT_FILE")"

if [[ -z $default ]]; then
  msg="No default agent set. Pick one with 'omanix-agent --pick' or declare omanix.apps.ai.defaultAgent."
  echo "$msg" >&2
  notify-send "Omanix Agent" "$msg" >/dev/null 2>&1 || true
  exit 1
fi

if ! is_agent "$default"; then
  echo "omanix-agent: unknown default agent '$default' (edit $DEFAULT_FILE or run --pick)." >&2
  exit 1
fi

bin="$(agent_bin "$default")"
if ! command -v "$bin" >/dev/null 2>&1; then
  opt="$(agent_option "$default")"
  msg="Agent '$default' is not installed. Enable $opt in your configuration and rebuild."
  echo "$msg" >&2
  notify-send "Omanix Agent" "$msg" >/dev/null 2>&1 || true
  exit 1
fi

# Prompt forwarding is per-agent; both claude and opencode accept a trailing
# positional prompt, so v1 forwards it inline (may need tuning per agent).
read -ra flags <<<"$(agent_flags "$default")"
cmd=("$bin" "${flags[@]}")
[[ -n $prompt ]] && cmd+=("$prompt")

if $inline; then
  exec "${cmd[@]}"
else
  exec omanix-launch-tui "--app-id=$APP_ID" -- "${cmd[@]}"
fi
