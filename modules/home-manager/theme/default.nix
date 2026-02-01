{
  config,
  lib,
  omanixLib,
  osConfig ? null,
  ...
}:

with lib;

let
  cfg = config.omanix;
  themeSchema = import ../../../lib/theme-schema.nix { inherit lib; };
  availableThemes = builtins.attrNames omanixLib.themes;

  # Check if we're running under NixOS with omanix enabled
  hasOsTheme =
    osConfig != null
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
    # IDLE / POWER MANAGEMENT OPTIONS
    # ═══════════════════════════════════════════════════════════════════

    idle = {
      screensaver = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the screensaver on idle.";
        };
        timeout = mkOption {
          type = types.int;
          default = 150;
          description = "Seconds of inactivity before screensaver starts (default: 150 = 2.5 minutes).";
        };
      };

      dimScreen = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable screen dimming on idle.";
        };
        timeout = mkOption {
          type = types.int;
          default = 840;
          description = "Seconds of inactivity before screen dims (default: 840 = 14 minutes).";
        };
        brightness = mkOption {
          type = types.int;
          default = 10;
          description = "Brightness percentage when dimmed (default: 10).";
        };
      };

      lock = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic screen locking on idle.";
        };
        timeout = mkOption {
          type = types.int;
          default = 900;
          description = "Seconds of inactivity before screen locks (default: 900 = 15 minutes).";
        };
      };

      dpms = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable DPMS (turn off screen) on idle.";
        };
        timeout = mkOption {
          type = types.int;
          default = 960;
          description = "Seconds of inactivity before screen turns off (default: 960 = 16 minutes).";
        };
      };

      suspend = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic suspend on idle.";
        };
        timeout = mkOption {
          type = types.int;
          default = 1800;
          description = "Seconds of inactivity before system suspends (default: 1800 = 30 minutes).";
        };
      };
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
      baseTheme
      // {
        assets =
          baseTheme.assets
          // (if cfg.wallpaperOverride != null then { wallpaper = cfg.wallpaperOverride; } else { });
      };
  };
}
