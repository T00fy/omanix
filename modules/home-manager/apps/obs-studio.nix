{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.obs;
in
{
  options.omanix.apps.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      obs-studio
    ];
  };
}
