{ config, pkgs, ... }:
let
  theme = config.omanix.activeTheme;
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = [ "${theme.assets.wallpaper}" ];
      wallpaper = [ ",${theme.assets.wallpaper}" ];
    };
  };
}
