{ config, lib, omanixLib, osConfig ? null, ... }:

with lib;

let
  cfg = config.omanix;
  themeSchema = import ../../../lib/theme-schema.nix { inherit lib; };
  availableThemes = builtins.attrNames omanixLib.themes;

  # Check if we're running under NixOS with omanix enabled
  hasOsTheme = osConfig != null 
    && osConfig ? omanix 
    && osConfig.omanix ? enable 
    && osConfig.omanix.enable 
    && osConfig.omanix ? theme;
in
{
  options.omanix = {
    # ═══════════════════════════════════════════════════════════════════
    # THEME OPTIONS
    # ═══════════════════════════════════════════════════════════════════

    theme = mkOption {
      type = types.enum availableThemes;
      default = if hasOsTheme then osConfig.omanix.theme else "tokyo-night";
      defaultText = literalExpression ''
        If running under NixOS with omanix.enable = true: osConfig.omanix.theme
        Otherwise: "tokyo-night"
      '';
      description = ''
        Select the active Omanix theme.
        
        When using Home Manager as a NixOS module with omanix.enable = true,
        this automatically inherits from the system-level omanix.theme setting.
        
        Available themes: ${concatStringsSep ", " availableThemes}
      '';
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

    # ═══════════════════════════════════════════════════════════════════
    # MONITOR OPTIONS
    # ═══════════════════════════════════════════════════════════════════

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

    # ═══════════════════════════════════════════════════════════════════
    # HYPRLAND VISUAL OPTIONS
    # ═══════════════════════════════════════════════════════════════════

    hyprland = {
      gaps = {
        inner = mkOption {
          type = types.int;
          default = 5;
          description = "Gap size between windows.";
        };
        outer = mkOption {
          type = types.int;
          default = 10;
          description = "Gap size between windows and screen edges.";
        };
      };

      border = {
        size = mkOption {
          type = types.int;
          default = 2;
          description = "Window border thickness in pixels.";
        };
      };

      rounding = mkOption {
        type = types.int;
        default = 0;
        description = "Window corner rounding radius in pixels.";
      };

      blur = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable window blur effects.";
        };
        size = mkOption {
          type = types.int;
          default = 2;
          description = "Blur size (intensity).";
        };
        passes = mkOption {
          type = types.int;
          default = 2;
          description = "Number of blur passes (higher = smoother but slower).";
        };
      };

      shadow = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable window shadows.";
        };
        range = mkOption {
          type = types.int;
          default = 2;
          description = "Shadow range (size).";
        };
      };

      animations = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = "Enable window animations.";
        };
      };
    };
  };

  config = {
    omanix.activeTheme =
      let
        baseTheme = omanixLib.themes.${cfg.theme};
      in
      baseTheme // {
        assets = baseTheme.assets // (
          if cfg.wallpaperOverride != null
          then { wallpaper = cfg.wallpaperOverride; }
          else { }
        );
      };
  };
}
