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
    hardware.steam-hardware.enable = true;
    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;

        # Update the package override:
        package = pkgs.steam.override {
          extraEnv = {
            # Tell Steam to scale its UI by 2x internally
            #STEAM_FORCE_DESKTOPUI_SCALING = "2.0";

            # Ensure GDK scale is consistent
            #GDK_SCALE = "2";
          };
        };
      };
      gamescope.enable = true;
      gamemode.enable = true;
    };
    environment.systemPackages = with pkgs; [
      mangohud
      protonup-qt
    ];
  };
}
