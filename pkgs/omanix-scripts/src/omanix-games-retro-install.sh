#!/usr/bin/env bash

# omanix:summary=Create a desktop launcher for a RetroArch ROM
# omanix:group=games
# omanix:examples=omanix-games-retro-install snes9x ~/roms/game.sfc

set -euo pipefail

cores_dir="${OMANIX_RETRO_CORES_DIR:-}"

if [[ -z $cores_dir || ! -d $cores_dir ]]; then
  echo "No libretro cores available (enable omanix.gaming.retroarch)." >&2
  exit 1
fi

core="${1:-}"
rom="${2:-}"

# Interactive core picker when no core was passed on the command line.
if [[ -z $core ]]; then
  rows="$(omanix-games-retro-cores | while IFS=$'\t' read -r label short; do
    printf '\t%s\t%s\n' "$label" "$short"
  done)"
  [[ -n $rows ]] || exit 1
  selection="$(omanix-menu-dmenu -p "Select system" <<<"$rows")" || exit 0
  [[ -n $selection ]] || exit 0
  core="$(cut -f2 <<<"$selection")"
fi

core_so="$cores_dir/${core}_libretro.so"
if [[ ! -e $core_so ]]; then
  echo "Core not installed: $core (looked for ${core}_libretro.so)" >&2
  exit 1
fi

# Interactive ROM picker when no ROM was passed on the command line.
if [[ -z $rom ]]; then
  rom="$(omanix-file-select "$HOME" | head -n1)" || exit 0
  [[ -n $rom ]] || exit 0
fi

if [[ ! -e $rom ]]; then
  echo "ROM not found: $rom" >&2
  exit 1
fi

rom="$(realpath -- "$rom")"
rom_name="$(basename -- "$rom")"
title="${rom_name%.*}"

# A filesystem-safe slug for the .desktop file name.
slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-//' -e 's/-$//')"
[[ -n $slug ]] || slug="rom"

apps_dir="$HOME/.local/share/applications"
mkdir -p "$apps_dir"
desktop="$apps_dir/omanix-retro-${slug}.desktop"

cat >"$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$title
Comment=Play $rom_name with RetroArch
Exec=retroarch -L "$core_so" "$rom"
Categories=Game;Emulator;
Terminal=false
EOF

echo "Created launcher: $desktop"
