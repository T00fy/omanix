#!/bin/bash

# omanix:summary=Switch the live Omanix theme (ephemeral runtime overlay)
# omanix:args=<theme-slug>
# omanix:examples=omanix-theme-set catppuccin-mocha | omanix-theme-set "Tokyo Night"

set -euo pipefail

# Runtime palette switch. Themes are built into the Nix store (all slugs live
# under $OMANIX_THEMES_DIR/<slug>/{colors.toml,shell.toml}); this only repoints
# the runtime current-theme link and pushes the palette to a running shell.
#
# The switch is an ephemeral overlay: home-manager activation always re-seeds
# current/theme to the declared omanix.theme, so a rebuild/restart reverts it.
# Nothing here is read back by activation.
#
# Palette only — the wallpaper is a separate axis (omanix-theme-bg-*).
#
# Security boundary: the only theme source is the trusted Nix store. A switch
# resolves a slug against $OMANIX_THEMES_DIR and repoints a symlink — no
# arbitrary path is ever accepted, copied, or staged, so there is no
# code-execution vector to filter (upstream's git-theme staging guards a
# ~/.config clone flow that omanix does not have). The traversal guard below
# (reject empty / leading-dot / contains-slash) is what keeps slug resolution
# inside the store.
#
# If an untrusted theme source is ever added (a --file <dir> or a cloned user
# themes dir), this becomes an execution vector and must permit color/asset
# data only — colors.toml, shell.toml, images under backgrounds/ — and deny any
# .lua, terminal configs (alacritty.toml, foot.ini, ghostty.conf, kitty.conf)
# and vscode.json, never following symlinks while staging.

usage() {
  cat <<USAGE
Usage: omanix-theme-set <theme-slug>

Switches the live shell theme to a built theme. Accepts a slug
(catppuccin-mocha) or a display name ("Tokyo Night"). Ephemeral: reverts to
the declared omanix.theme on the next rebuild or shell restart.
USAGE
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  "")
    usage >&2
    exit 1
    ;;
esac

: "${OMANIX_THEMES_DIR:?OMANIX_THEMES_DIR is not set}"

CURRENT_THEME_PATH="$HOME/.local/state/omanix/current/theme"
THEME_SET_LOCK="${XDG_RUNTIME_DIR:-/tmp}/omanix-theme-set.lock"

# Normalize a display name to a slug: strip <...> placeholders, lowercase,
# spaces to dashes (matches how the enum slugs are keyed).
THEME_SLUG=$(echo "$1" | sed -E 's/<[^>]+>//g' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

if [[ -z $THEME_SLUG || $THEME_SLUG == .* || $THEME_SLUG == */* ]]; then
  echo "Invalid theme name: $1" >&2
  exit 1
fi

if [[ ! -d $OMANIX_THEMES_DIR/$THEME_SLUG ]]; then
  echo "Theme '$THEME_SLUG' does not exist" >&2
  exit 1
fi

# Serialize concurrent switches (keybind vs. shell double-click IPC).
exec 9>"$THEME_SET_LOCK"
flock 9

# Ephemeral overlay: repoint the runtime current-theme link into the store.
mkdir -p "$(dirname "$CURRENT_THEME_PATH")"
ln -sfn "$OMANIX_THEMES_DIR/$THEME_SLUG" "$CURRENT_THEME_PATH"

# Re-theme a running shell immediately. A down shell no-ops (best-effort -q)
# and picks up current/theme on its next launch.
colors_b64=$([[ -f $CURRENT_THEME_PATH/colors.toml ]] && base64 -w0 "$CURRENT_THEME_PATH/colors.toml" || true)
shell_b64=$([[ -f $CURRENT_THEME_PATH/shell.toml ]] && base64 -w0 "$CURRENT_THEME_PATH/shell.toml" || true)
omanix-shell -q shell applyTheme "$colors_b64" "$shell_b64" || true

flock -u 9

# Best-effort downstream palette-only targets. Called only if present,
# never hard-depended on. Browser color is not here: it is declarative under Nix
# (omanix.browserPolicy via environment.etc), and /etc is read-only, so browsers
# track only the declared theme — a runtime switch does not retint them.
for cmd in \
  omanix-theme-set-tmux \
  omanix-theme-set-claude \
  omanix-theme-set-pi; do
  command -v "$cmd" >/dev/null 2>&1 && "$cmd" || true
done
