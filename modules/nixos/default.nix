{ config, lib, pkgs, ... }:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;
  availableThemes = builtins.attrNames omanixLib.themes;
in
{
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

    activeTheme = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      description = "The fully resolved theme data (read-only, computed from omanix.theme)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Resolve the active theme from the theme name
    omanix.activeTheme = omanixLib.themes.${cfg.theme};

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
