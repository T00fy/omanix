{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.spotatui;
in
{
  options.omanix.apps.spotatui = {
    enable = lib.mkEnableOption "Spotatui" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotatui ];
  };
}
