{ lib }:
with lib;
types.submodule {
  options = {
    # Metadata
    meta.name = mkOption { type = types.str; };
    meta.slug = mkOption { type = types.str; };

    # Assets
    assets.wallpaper = mkOption { type = types.path; };

    # UI Colors
    colors.background = mkOption { type = types.str; }; # #1a1b26
    colors.foreground = mkOption { type = types.str; }; # #a9b1d6
    colors.cursor = mkOption { type = types.str; };
    colors.accent = mkOption { type = types.str; };     # #7aa2f7
    colors.selection_background = mkOption { type = types.str; };
    colors.selection_foreground = mkOption { type = types.str; };

    # ANSI Palette
    colors.color0 = mkOption { type = types.str; };
    colors.color1 = mkOption { type = types.str; };
    colors.color2 = mkOption { type = types.str; };
    colors.color3 = mkOption { type = types.str; };
    colors.color4 = mkOption { type = types.str; };
    colors.color5 = mkOption { type = types.str; };
    colors.color6 = mkOption { type = types.str; };
    colors.color7 = mkOption { type = types.str; };
    colors.color8 = mkOption { type = types.str; };
    colors.color9 = mkOption { type = types.str; };
    colors.color10 = mkOption { type = types.str; };
    colors.color11 = mkOption { type = types.str; };
    colors.color12 = mkOption { type = types.str; };
    colors.color13 = mkOption { type = types.str; };
    colors.color14 = mkOption { type = types.str; };
    colors.color15 = mkOption { type = types.str; };
  };
}
