{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    # New windowrule syntax for Hyprland 0.53+
    # Format: windowrule = EFFECT VALUE, match:MATCHER PATTERN
    windowrule = [
      # Opacity - new syntax with match:class
      "opacity 0.97 0.9, match:class .*"
      "opacity 1.0 1.0, match:class ^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer)$"
      "opacity 1.0 1.0, match:class ^(chromium|google-chrome)$, match:title .*YouTube.*"
      # Floating
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^(xdg-desktop-portal-gtk)$"
      # Geometry
      "center on, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 875 600, match:class ^(org.pulseaudio.pavucontrol)$"
      # Idle Inhibit
      "idleinhibit fullscreen, match:class ^(chromium|google-chrome)$"
      "idleinhibit fullscreen, match:class ^(vlc|mpv)$"
    ];

    # Layer rules - new syntax with match:namespace and boolean values
    layerrule = [
      "blur on, match:namespace waybar"
      "blur on, match:namespace wofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 0.5, match:namespace waybar"
      "ignore_alpha 0.5, match:namespace wofi"
      "ignore_alpha 0.5, match:namespace notifications"
    ];
  };
}
