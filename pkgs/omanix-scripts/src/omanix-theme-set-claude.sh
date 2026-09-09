#!/bin/bash

# omanix:summary=Sync the generated Omanix theme to Claude Code
# omanix:args=[--activate]
# omanix:hidden=true

set -euo pipefail

CLAUDE_SOURCE_PATH="$HOME/.local/state/omanix/current/theme/claude.json"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_THEME_PATH="$CLAUDE_CONFIG_DIR/themes/omanix.json"
CLAUDE_SETTINGS_PATH="$CLAUDE_CONFIG_DIR/settings.json"
CLAUDE_ACTIVATE=0

usage() {
  echo "Usage: omanix-theme-set-claude [--activate]"
}

for arg in "$@"; do
  case "$arg" in
    --activate)
      CLAUDE_ACTIVATE=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f $CLAUDE_SOURCE_PATH ]]; then
  if ((CLAUDE_ACTIVATE == 1)); then
    echo "Claude Code theme source missing: $CLAUDE_SOURCE_PATH" >&2
    echo "Rebuild after selecting an Omanix theme (omanix.theme), or run omanix-theme-set." >&2
    exit 1
  fi

  exit 0
fi

if ((CLAUDE_ACTIVATE == 0)) && [[ ! -d $CLAUDE_CONFIG_DIR ]]; then
  exit 0
fi

write_setting_theme() {
  local tmp

  if [[ -f $CLAUDE_SETTINGS_PATH ]]; then
    tmp=$(mktemp "$CLAUDE_SETTINGS_PATH.XXXXXX")
    jq '.theme = "custom:omanix"' "$CLAUDE_SETTINGS_PATH" >"$tmp"
    mv "$tmp" "$CLAUDE_SETTINGS_PATH"
  else
    cat >"$CLAUDE_SETTINGS_PATH" <<EOF
{
  "theme": "custom:omanix"
}
EOF
  fi
}

# Claude Code watches ~/.claude/themes and hot-reloads the file on change,
# so running sessions retint without a restart.
mkdir -p "$(dirname "$CLAUDE_THEME_PATH")"
tmp=$(mktemp "$CLAUDE_THEME_PATH.XXXXXX")
cp "$CLAUDE_SOURCE_PATH" "$tmp"
mv "$tmp" "$CLAUDE_THEME_PATH"

if ((CLAUDE_ACTIVATE == 1)); then
  write_setting_theme
fi
