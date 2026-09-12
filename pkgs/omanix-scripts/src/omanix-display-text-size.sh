#!/usr/bin/env bash

# omanix:summary=Scale text everywhere — omanix shell font + GTK apps
# omanix:args=[size|reset]
# omanix:examples=omanix-display-text-size | omanix-display-text-size 16 | omanix-display-text-size reset

# One knob for apparent text size, anchored to the shell default of 12px. It
# drives two settings in lockstep:
#   • the omanix shell's font base-size (~/.config/omanix/shell.toml [font]) —
#     the live-watched user overlay layered on top of the active theme, so shell
#     text re-flows without a restart (Color.qml userShellFile).
#   • GNOME/GTK's text-scaling-factor (12px -> 1.0, quantized so the GTK
#     interface font lands on a whole point size, so 16 -> 15pt/11pt = 1.3636).
#
# Both are ephemeral runtime overlays: the declared default is
# omanix.monitor.textSize (rendered into each theme's shell.toml in the store)
# and a rebuild re-asserts it by stripping this overlay's base-size. Terminal
# font size is NOT touched here — terminal configs are store-generated and
# read-only in omanix; their size is declaratively derived. Accepts an integer
# from 9 to 20 (px).

MIN=9
MAX=20
GKEY_SCHEMA="org.gnome.desktop.interface"
GKEY_NAME="text-scaling-factor"

# Anchor: 12px shell base == factor 1.0. The declared default is injected by the
# Nix wrapper (omanix.monitor.textSize); fall back to 12 when built standalone.
SHELL_DEFAULT_PX="${OMANIX_TEXT_SIZE_DEFAULT:-12}"

shell_config="$HOME/.config/omanix/shell.toml"

usage() {
  echo "Usage: omanix-display-text-size [size|reset]"
  echo "  (no args)   print the current text size and GTK factor"
  echo "  <size>      set text size in px ($MIN–$MAX); shell + GTK together"
  echo "  reset       drop the override so the declared default applies"
}

# ---- shell base-size: the rem root every shell type size derives from ----

# Print the base-size currently set under [font], or nothing if unset.
current_base_size() {
  [[ -f $shell_config ]] || return 0
  awk '
    /^[[:space:]]*\[/ { in_font = ($0 ~ /^[[:space:]]*\[font\]([[:space:]]|$)/); next }
    in_font && /^[[:space:]]*base-size[[:space:]]*=/ {
      v = $0
      sub(/^[^=]*=[[:space:]]*/, "", v)
      sub(/[[:space:]]*(#.*)?$/, "", v)
      print v
      exit
    }
  ' "$shell_config"
}

# Upsert base-size under [font]: replace it in place if present, insert it into
# an existing [font] section, or append a fresh [font] section otherwise. Other
# sections and keys in the user override are left untouched.
set_base_size() {
  local size="$1"
  mkdir -p "$(dirname "$shell_config")"

  if [[ ! -f $shell_config ]]; then
    printf '[font]\nbase-size = %s\n' "$size" >"$shell_config"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v val="$size" '
    function emit_base() { print "base-size = " val; done = 1 }
    /^[[:space:]]*\[/ {
      if (in_font && !done) emit_base()
      in_font = ($0 ~ /^[[:space:]]*\[font\]([[:space:]]|$)/)
      print
      next
    }
    in_font && /^[[:space:]]*base-size[[:space:]]*=/ {
      if (!done) emit_base()
      next
    }
    { print }
    END {
      if (in_font && !done) emit_base()
      if (!done) {
        if (NR > 0) print ""
        print "[font]"
        emit_base()
      }
    }
  ' "$shell_config" >"$tmp"
  mv "$tmp" "$shell_config"
}

# Drop the base-size line, returning the shell to the theme/declared size.
reset_base_size() {
  [[ -f $shell_config ]] || return 0
  local tmp
  tmp="$(mktemp)"
  awk '
    /^[[:space:]]*\[/ { in_font = ($0 ~ /^[[:space:]]*\[font\]([[:space:]]|$)/) }
    in_font && /^[[:space:]]*base-size[[:space:]]*=/ { next }
    { print }
  ' "$shell_config" >"$tmp"
  mv "$tmp" "$shell_config"
}

# ---- GTK text-scaling-factor ----

# Point size of the GTK interface font (font-name), used to quantize the
# scaling factor. Falls back to the GNOME default when unreadable.
gtk_font_pt() {
  local name pt
  name="$(gsettings get "$GKEY_SCHEMA" font-name 2>/dev/null)"
  pt="${name%\'}"
  pt="${pt##* }"
  if [[ $pt =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$pt"
  else
    echo 11
  fi
}

set_factor() {
  gsettings set "$GKEY_SCHEMA" "$GKEY_NAME" "$1" 2>/dev/null || true
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  "")
    cur="$(current_base_size)"
    size="${cur:-$SHELL_DEFAULT_PX (default)}"
    factor="$(gsettings get "$GKEY_SCHEMA" "$GKEY_NAME" 2>/dev/null)"
    printf 'text size: %s px\ngtk text-scaling-factor: %s\n' "$size" "$factor"
    exit 0
    ;;
  reset | default)
    reset_base_size
    gsettings reset "$GKEY_SCHEMA" "$GKEY_NAME" 2>/dev/null || true
    exit 0
    ;;
esac

size="$1"
if [[ ! $size =~ ^[0-9]+$ ]] || ((size < MIN || size > MAX)); then
  echo "Size must be an integer between $MIN and $MAX (px)." >&2
  usage >&2
  exit 1
fi

# Shell side: base-size in px (the omanix shell's rem root).
set_base_size "$size"

# GTK side: multiplier anchored so 12px == 1.0, quantized so the interface font
# renders at a whole point size. Raw ratios yield fractional point sizes, which
# GTK4 menus clip at the ascenders on scale-1 monitors.
factor="$(awk -v s="$size" -v b="$SHELL_DEFAULT_PX" -v f="$(gtk_font_pt)" \
  'BEGIN { printf "%.4f", int(f * s / b + 0.5) / f }')"
set_factor "$factor"
