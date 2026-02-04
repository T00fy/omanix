{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.spotatui;
in
{
  options.omanix.spotatui = {
    enable = lib.mkEnableOption "Spotatui" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotatui ];
  };
}
