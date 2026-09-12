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

  hasOsConfig =
    osConfig != null && osConfig ? omanix && osConfig.omanix ? enable && osConfig.omanix.enable;
in
{
  options.omanix = {
    # ═══════════════════════════════════════════════════════════════════
    # THEME OPTIONS
    # ═══════════════════════════════════════════════════════════════════

    theme = mkOption {
      type = types.enum availableThemes;
      default = if hasOsConfig then osConfig.omanix.theme else "tokyo-night";
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

    menu = {
      width = lib.mkOption {
        type = lib.types.int;
        default = if cfg.monitor.scale == "1" then 369 else 295;
        description = "Menu width in pixels.";
      };
      maxHeight = lib.mkOption {
        type = lib.types.int;
        default = if cfg.monitor.scale == "1" then 788 else 630;
        description = "Menu max height in pixels.";
      };
    };

    wallpaperIndex = mkOption {
      type = types.int;
      default = if hasOsConfig then osConfig.omanix.wallpaperIndex else 0;
      defaultText = literalExpression ''
        If running under NixOS with omanix.enable = true: osConfig.omanix.wallpaperIndex
        Otherwise: 0
      '';
      description = "Index of the wallpaper to use from the theme's wallpaper list.";
    };

    wallpaperOverride = mkOption {
      type = types.nullOr types.path;
      default = if hasOsConfig then osConfig.omanix.wallpaperOverride else null;
      defaultText = literalExpression ''
        If running under NixOS with omanix.enable = true: osConfig.omanix.wallpaperOverride
        Otherwise: null
      '';
      description = "Override the theme's wallpaper with a specific local file (takes priority over index).";
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
        logo = mkOption {
          type = types.path;
          default = ../../../assets/branding/logo.txt;
          description = "Path to the ASCII text file displayed by the screensaver.";
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

      textSize = mkOption {
        type = types.int;
        default = 12;
        description = ''
          Declared shell font base-size in px (9–20), the anchor for the Display
          panel's Text Size slider and `omanix-display-text-size`. Rendered into
          every theme's shell.toml as `[font] base-size`. The runtime slider is
          an ephemeral overlay (~/.config/omanix/shell.toml) that a rebuild
          re-asserts back to this value.
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
        selectedWallpaper =
          if cfg.wallpaperOverride != null then
            cfg.wallpaperOverride
          else if builtins.length baseTheme.assets.wallpapers > cfg.wallpaperIndex then
            builtins.elemAt baseTheme.assets.wallpapers cfg.wallpaperIndex
          else
            builtins.elemAt baseTheme.assets.wallpapers 0;
      in
      baseTheme
      // {
        assets = baseTheme.assets // {
          wallpaper = selectedWallpaper;
        };
      };
  };
}
