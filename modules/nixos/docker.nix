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
  config = lib.mkIf (cfg.enable && cfg.docker.enable) {
    virtualisation.docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    environment.systemPackages = with pkgs; [
      docker-compose
      lazydocker
    ];
  };
}
