{ pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "fcitx5 -d -r"
      "hypridle"
      "mako"
      "waybar"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
    ];
  };
}
