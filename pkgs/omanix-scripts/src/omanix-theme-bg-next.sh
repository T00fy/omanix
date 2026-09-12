#!/bin/bash

# omanix:summary=Cycle to the next background for the current theme
# omanix:examples=omanix-theme-bg-next

# One source of truth: the current/background symlink (repointed by
# omanix-theme-bg-set, re-seeded to the declared wallpaper on rebuild).
# Cycles the active theme's declared wallpapers (current/theme/backgrounds).

THEME_BACKGROUNDS_PATH="$HOME/.local/state/omanix/current/theme/backgrounds/"
CURRENT_BACKGROUND_LINK="$HOME/.local/state/omanix/current/background"

mapfile -d '' -t BACKGROUNDS < <(
  find -L "$THEME_BACKGROUNDS_PATH" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) \
    -print0 2>/dev/null | sort -z
)
TOTAL=${#BACKGROUNDS[@]}

if (( TOTAL == 0 )); then
  echo "No background was found for theme" >&2
  exit 1
fi

# Resolve the current background through the symlink so a match is found
# regardless of the store path the wallpaper lives at.
CURRENT_BACKGROUND=$(readlink -f "$CURRENT_BACKGROUND_LINK" 2>/dev/null)

# Find current background index
INDEX=-1
for i in "${!BACKGROUNDS[@]}"; do
  if [[ $(readlink -f "${BACKGROUNDS[$i]}") == "$CURRENT_BACKGROUND" ]]; then
    INDEX=$i
    break
  fi
done

# Get next background (wrap around)
if (( INDEX == -1 )); then
  # Use the first background when no match was found
  NEW_BACKGROUND="${BACKGROUNDS[0]}"
else
  NEXT_INDEX=$(((INDEX + 1) % TOTAL))
  NEW_BACKGROUND="${BACKGROUNDS[$NEXT_INDEX]}"
fi

omanix-theme-bg-set "$NEW_BACKGROUND"
