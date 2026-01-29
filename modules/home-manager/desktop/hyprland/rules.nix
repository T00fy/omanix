{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    # Window Rules
    windowrule = [
      # Screenshot Editor (Satty) - Float and Center
      "float on, match:class ^(com.gabm.satty)$"
      "center on, match:class ^(com.gabm.satty)$"
      "size 80% 80%, match:class ^(com.gabm.satty)$"
      "dim_around on, match:class ^(com.gabm.satty)$" # Fixed: dimaround -> dim_around
      
      # Existing rules...
      "opacity 0.97 0.9, match:class .*"
      "opacity 1.0 1.0, match:class ^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer|com.gabm.satty)$"
      "opacity 1.0 1.0, match:class ^(chromium|google-chrome)$, match:title .*YouTube.*"
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^(xdg-desktop-portal-gtk)$"
      "center on, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 875 600, match:class ^(org.pulseaudio.pavucontrol)$"
    ];

    # Layer Rules
    layerrule = [
      # Fixed: noanim -> no_anim and added explicit 'on' value
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
