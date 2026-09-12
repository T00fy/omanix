#!/usr/bin/env bash

# omanix:summary=List installed libretro cores with friendly system labels
# omanix:group=games
# omanix:examples=omanix-games-retro-cores

set -euo pipefail

cores_dir="${OMANIX_RETRO_CORES_DIR:-}"

if [[ -z $cores_dir || ! -d $cores_dir ]]; then
  echo "No libretro cores available (enable omanix.gaming.retroarch)." >&2
  exit 1
fi

# Map a core's short name (the part before "_libretro.so") to a friendly
# system label. Cores not listed fall back to their raw short name.
label_for() {
  case "$1" in
    snes9x | snes9x2010 | bsnes | bsnes_hd_beta) echo "Super Nintendo (SNES)" ;;
    nestopia | fceumm | mesen | quicknes) echo "Nintendo (NES)" ;;
    mgba | vba_next | gpsp) echo "Game Boy Advance" ;;
    gambatte | sameboy) echo "Game Boy / Color" ;;
    mupen64plus_next | parallel_n64) echo "Nintendo 64" ;;
    melonds | desmume | desmume2015) echo "Nintendo DS" ;;
    citra | citra_canary) echo "Nintendo 3DS" ;;
    dolphin) echo "GameCube / Wii" ;;
    mednafen_psx_hw | mednafen_psx | pcsx_rearmed | swanstation | duckstation) echo "PlayStation (PSX)" ;;
    ppsspp) echo "PlayStation Portable (PSP)" ;;
    genesis_plus_gx | picodrive | blastem) echo "Sega Genesis / Master System" ;;
    mednafen_saturn | yabause | kronos | beetle_saturn) echo "Sega Saturn" ;;
    flycast | reicast) echo "Sega Dreamcast" ;;
    mame | mame2003_plus | mame2003 | mame2010 | fbneo | fbalpha2012) echo "Arcade (MAME)" ;;
    pce | mednafen_pce | mednafen_pce_fast | mednafen_supergrafx) echo "PC Engine / TurboGrafx-16" ;;
    mednafen_wswan) echo "WonderSwan" ;;
    mednafen_ngp) echo "Neo Geo Pocket" ;;
    o2em) echo "Odyssey 2" ;;
    prosystem) echo "Atari 7800" ;;
    stella | stella2014) echo "Atari 2600" ;;
    virtualjaguar) echo "Atari Jaguar" ;;
    puae | puae2021) echo "Commodore Amiga" ;;
    vice_x64 | vice_x64sc) echo "Commodore 64" ;;
    dosbox_pure | dosbox_core | dosbox_svn) echo "DOS" ;;
    scummvm) echo "ScummVM" ;;
    *) echo "$1" ;;
  esac
}

shopt -s nullglob
cores=("$cores_dir"/*_libretro.so)

if ((${#cores[@]} == 0)); then
  echo "No libretro cores found in $cores_dir." >&2
  exit 1
fi

for core in "${cores[@]}"; do
  short="$(basename "$core" _libretro.so)"
  printf '%s\t%s\n' "$(label_for "$short")" "$short"
done | sort -f
