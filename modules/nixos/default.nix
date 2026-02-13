{ config, lib, ... }:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;
  availableThemes = builtins.attrNames omanixLib.themes;
in
{
  imports = [
    ./login.nix
    ./steam.nix
    ./libreoffice.nix
  ];

  options.omanix = {
    enable = lib.mkEnableOption "Omanix desktop environment";

    theme = lib.mkOption {
      type = lib.types.enum availableThemes;
      default = "tokyo-night";
      description = ''
        The active Omanix theme. This setting is inherited by Home Manager
        when using Home Manager as a NixOS module.

        Available themes: ${lib.concatStringsSep ", " availableThemes}
      '';
      example = "tokyo-night";
    };

    wallpaperIndex = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Index of the wallpaper to use from the theme's wallpaper list.";
    };

    wallpaperOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Override the theme's wallpaper with a specific local file (takes priority over index).";
    };

    activeTheme = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      description = "The fully resolved theme data (read-only, computed from omanix.theme)";
    };

    steam.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Steam and gaming tools (requires omanix.enable).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
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

    # ═══════════════════════════════════════════════════════════════════
    # FONT CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════
    fonts.fontconfig = {
      antialias = true;
      hinting = {
        enable = true;
        autohint = false;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };

    # ═══════════════════════════════════════════════════════════════════
    # HARDWARE
    # ═══════════════════════════════════════════════════════════════════
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # ═══════════════════════════════════════════════════════════════════
    # SERVICES
    # ═══════════════════════════════════════════════════════════════════
    services.blueman.enable = true;

    # ═══════════════════════════════════════════════════════════════════
    # PROGRAMS
    # ═══════════════════════════════════════════════════════════════════
    programs.zsh.enable = true;
  };
}
