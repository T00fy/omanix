#!/bin/bash

# omanix:summary=Sync the generated Omanix Pi theme
# omanix:args=[--activate]
# omanix:hidden=true

set -euo pipefail

CURRENT_THEME_PATH="$HOME/.local/state/omanix/current/theme"
PI_SOURCE_PATH="$CURRENT_THEME_PATH/pi.json"
PI_AGENT_DIR="$HOME/.pi/agent"
PI_THEME_DIR="$PI_AGENT_DIR/themes"
PI_THEME_PATH="$PI_THEME_DIR/omanix-system.json"
PI_SETTINGS_PATH="$PI_AGENT_DIR/settings.json"
PI_ACTIVATE=0

usage() {
  echo "Usage: omanix-theme-set-pi [--activate]"
}

for arg in "$@"; do
  case "$arg" in
    --activate)
      PI_ACTIVATE=1
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

if [[ ! -f $PI_SOURCE_PATH ]]; then
  if ((PI_ACTIVATE == 1)); then
    echo "Pi theme source missing: $PI_SOURCE_PATH" >&2
    echo "Rebuild after selecting an Omanix theme (omanix.theme), or run omanix-theme-set." >&2
    exit 1
  fi

  exit 0
fi

if ((PI_ACTIVATE == 0)) && [[ ! -d $PI_AGENT_DIR ]]; then
  exit 0
fi

write_setting_theme() {
  local tmp

  mkdir -p "$PI_AGENT_DIR"

  if [[ -f $PI_SETTINGS_PATH ]]; then
    tmp=$(mktemp "$PI_SETTINGS_PATH.XXXXXX")
    jq '.theme = "omanix-system"' "$PI_SETTINGS_PATH" >"$tmp"
    mv "$tmp" "$PI_SETTINGS_PATH"
  else
    cat >"$PI_SETTINGS_PATH" <<EOF
{
  "theme": "omanix-system"
}
EOF
  fi
}

mkdir -p "$PI_THEME_DIR"
tmp=$(mktemp "$PI_THEME_PATH.XXXXXX")
cp "$PI_SOURCE_PATH" "$tmp"
mv "$tmp" "$PI_THEME_PATH"

if ((PI_ACTIVATE == 1)); then
  write_setting_theme
fi
