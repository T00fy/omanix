{
  config,
  lib,
  omarchyLib,
  ...
}:

with lib;

let
  cfg = config.omarchy;
  # Import the schema definition
  themeSchema = import ../../../lib/theme-schema.nix { inherit lib; };
in
{
  # 1. DEFINE OPTIONS
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

    activeTheme = mkOption {
      type = themeSchema;
      readOnly = true;
      description = "The fully resolved theme data (colors + assets).";
    };

    # New nested option for monitor scaling
    monitor = {
      scale = mkOption {
        type = types.str;
        default = "auto";
        description = ''
          Monitor scaling factor. Can be a number (e.g., "1", "1.5", "2") 
          or "auto" for automatic detection.
        '';
      };
    };
    monitors = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Connector name, e.g. DP-2";
            };
            workspaces = mkOption {
              type = types.listOf types.int;
              description = "Workspaces to pin to this monitor";
            };
          };
        }
      );
      default = [
        {
          name = "";
          workspaces = [
            1
            2
            3
            4
            5
          ];
        }
      ];
      description = "Hardware monitor layout and workspace assignments.";
    };

  };

  config = {
    omarchy.activeTheme =
      let
        # Fetch the base theme data
        baseTheme = omarchyLib.themes.${cfg.theme};
      in
      # Merge in wallpaper override if it exists
      baseTheme
      // {
        assets =
          baseTheme.assets
          // (if cfg.wallpaperOverride != null then { wallpaper = cfg.wallpaperOverride; } else { });
      };
  };
}
