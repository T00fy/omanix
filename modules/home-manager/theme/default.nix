{ config, lib, omarchyLib, ... }:

with lib;

let
  cfg = config.omarchy;
  # Import the schema definition
  themeSchema = import ../../../lib/theme-schema.nix { inherit lib; };
in
{
  options.omarchy = {
    theme = mkOption {
      type = types.enum [ "tokyo-night" ];
      default = "tokyo-night";
      description = "Select the active Omarchy theme.";
    };

    wallpaperOverride = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Override the theme's default wallpaper with a local file.";
    };

    # Internal read-only option that other modules will use
    activeTheme = mkOption {
      type = themeSchema;
      readOnly = true;
      description = "The fully resolved theme data (colors + assets).";
    };
  };

  config = {
    omarchy.activeTheme = 
      let
        # Fetch the base theme data
        baseTheme = omarchyLib.themes.${cfg.theme};
      in
      # Merge in wallpaper override if it exists
      baseTheme // {
        assets = baseTheme.assets // (
          if cfg.wallpaperOverride != null 
          then { wallpaper = cfg.wallpaperOverride; }
          else {}
        );
      };
  };
}
