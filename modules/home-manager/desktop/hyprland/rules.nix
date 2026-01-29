{ config, lib, ... }:
let
  cfg = config.omarchy;
  # Generate ["1, monitor:DP-2" "2, monitor:DP-2" ...]
  workspaceBindings = lib.concatLists (
    map (m: map (ws: "${toString ws}, monitor:${m.name}") m.workspaces) cfg.monitors
  );
in
{
  wayland.windowManager.hyprland.settings = {
    # Generate rules dynamically from config
    workspace = workspaceBindings;

    windowrule = [
      "float on, match:class ^(com.gabm.satty|satty)$"
      "center on, match:class ^(com.gabm.satty|satty)$"
      "size 80% 80%, match:class ^(com.gabm.satty|satty)$"
      "dim_around on, match:class ^(com.gabm.satty|satty)$"
      "no_anim on, match:class ^(com.gabm.satty|satty)$"
      "opacity 1.0 1.0, match:class ^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer|com.gabm.satty)$"
      "opacity 1.0 1.0, match:class ^(chromium|google-chrome)$, match:title .*YouTube.*"
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^(xdg-desktop-portal-gtk)$"
      "center on, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 875 600, match:class ^(org.pulseaudio.pavucontrol)$"
    ];

    layerrule = [
      "no_anim on, match:namespace ^(selection)$"
      "no_anim on, match:namespace ^(wayfreeze)$"
      "blur on, match:namespace waybar"
      "blur on, match:namespace wofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 0.5, match:namespace waybar"
      "ignore_alpha 0.5, match:namespace wofi"
      "ignore_alpha 0.5, match:namespace notifications"
    ];
  };
}
