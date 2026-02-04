{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.obsidian;
in
{
  options.omanix.apps.obsidian = {
    enable = lib.mkEnableOption "Obsidian";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.obsidian
    ];
  };
}
