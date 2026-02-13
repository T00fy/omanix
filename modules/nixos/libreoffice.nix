{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix;
in
{
  options.omanix.libreoffice = {
    enable = lib.mkEnableOption "LibreOffice suite" // {
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable && cfg.libreoffice.enable) {
    environment.systemPackages = with pkgs; [
      libreoffice-fresh
    ];
  };
}
