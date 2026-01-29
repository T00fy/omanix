{ config, pkgs, ... }: 
let
  wallpaper = config.omanix.activeTheme.assets.wallpaper;
in {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "fcitx5 -d -r"
      "hypridle"
      "mako"
      "waybar"
      "swayosd-server"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill"
    ];
  };
}
