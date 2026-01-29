{ lib }:
with lib;
types.submodule {
  options = {
    meta.name = mkOption { type = types.str; };
    meta.slug = mkOption { type = types.str; };
    meta.icon_theme = mkOption { type = types.str; };

    assets.wallpaper = mkOption { type = types.path; };

    # Bat theme configuration
    bat.name = mkOption { 
      type = types.str; 
      description = "The bat theme name (as it appears in bat --list-themes)";
    };
    bat.url = mkOption { 
      type = types.str; 
      description = "URL to the .tmTheme file";
    };
    bat.sha256 = mkOption { 
      type = types.str; 
      description = "SHA256 hash of the theme file";
    };

    # UI Colors
    colors.background = mkOption { type = types.str; }; 
    colors.foreground = mkOption { type = types.str; }; 
    colors.cursor = mkOption { type = types.str; };
    colors.accent = mkOption { type = types.str; };     
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
