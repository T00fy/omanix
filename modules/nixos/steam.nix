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
  config = lib.mkIf (cfg.enable && cfg.steam.enable) {
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports for Steam Remote Play
      };
      gamescope.enable = true;
      gamemode.enable = true;
    };
    environment.systemPackages = with pkgs; [
      mangohud
    ];
  };
}
