{ config, pkgs, ... }:
let
  theme = config.omarchy.activeTheme;
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
