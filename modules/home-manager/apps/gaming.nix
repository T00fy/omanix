{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.gaming;

  retroarchPackage = pkgs.retroarch.withCores (libretro: map (n: libretro.${n}) cfg.retroarch.cores);
in
{
  options.omanix.gaming = {
    battlenet.enable = lib.mkEnableOption "Battle.net via umu-launcher + GE-Proton";

    retroarch = {
      enable = lib.mkEnableOption "RetroArch with a declarative set of libretro cores";

      cores = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "snes9x"
          "nestopia"
          "mgba"
          "genesis-plus-gx"
          "mupen64plus"
          "beetle-psx-hw"
          "ppsspp"
          "flycast"
          "beetle-saturn"
          "mame2003-plus"
          "melonds"
        ];
        description = ''
          Libretro cores to bundle with RetroArch. Each entry is an attribute
          name under `pkgs.libretro`.
        '';
        example = [
          "snes9x"
          "mgba"
        ];
      };

      package = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        internal = true;
        default = retroarchPackage;
        description = "RetroArch built with the configured cores.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.retroarch.enable {
      home.packages = [ cfg.retroarch.package ];
    })

    (lib.mkIf cfg.battlenet.enable {
      home.packages = [ pkgs.umu-launcher ];

      xdg.desktopEntries.battlenet = {
        name = "Battle.net";
        comment = "Launch Battle.net through umu + GE-Proton";
        exec = "omanix-gaming-battlenet play";
        icon = "battlenet";
        categories = [ "Game" ];
        terminal = false;
      };
    })
  ];
}
