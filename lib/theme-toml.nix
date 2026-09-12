{ lib }:

let
  inherit (import ./color-utils.nix { inherit lib; }) mix darken lighten;
in

# Render an omarchy-compatible colors.toml string from an omanix palette.
{
  colors,
  mode ? "dark",
}:

let
  # Derived colors with no direct palette source.
  orange = mix colors.color1 colors.color3 50; # red + yellow
  brown = mix orange colors.background 60;
in
''
  mode = "${mode}"

  accent = "${colors.accent}"
  selection = "${colors.selection_background}"
  muted = "${colors.color8}"

  background = "${colors.background}"
  dark_background = "${darken colors.background 27}"
  darker_background = "${darken colors.background 47}"
  lighter_background = "${lighten colors.background 9}"

  foreground = "${colors.foreground}"
  dark_foreground = "${darken colors.foreground 45}"
  light_foreground = "${lighten colors.foreground 7}"
  bright_foreground = "${colors.cursor}"

  red = "${colors.color1}"
  yellow = "${colors.color3}"
  orange = "${orange}"
  green = "${colors.color2}"
  cyan = "${colors.color6}"
  blue = "${colors.color4}"
  magenta = "${colors.color5}"
  brown = "${brown}"

  bright_red = "${colors.color9}"
  bright_yellow = "${colors.color11}"
  bright_green = "${colors.color10}"
  bright_cyan = "${colors.color14}"
  bright_blue = "${colors.color12}"
  bright_magenta = "${colors.color13}"
''
