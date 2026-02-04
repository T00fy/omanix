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
        remotePlay.openFirewall = true;
        
        # --- ADD THIS SECTION ---
        package = pkgs.steam.override {
          extraEnv = {
            # Reset GDK_SCALE to 1 so Steam doesn't double-scale itself
            GDK_SCALE = "1"; 
            # Optional: Force specific Steam scaling factor if 1 is too small
            # STEAM_FORCE_DESKTOPUI_SCALING = "1.0"; 
          };
        };
        # ------------------------
      };
      gamescope.enable = true;
      gamemode.enable = true;
    };
    environment.systemPackages = with pkgs; [
      mangohud
    ];
  };
}
