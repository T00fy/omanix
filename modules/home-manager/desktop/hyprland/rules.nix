{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    # Use windowrulev2 for everything
    windowrulev2 = [
      # Opacity
      "opacity 0.97 0.9, class:(.*)"
      "opacity 1 1, class:^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer)$"
      "opacity 1 1, class:^(chromium|google-chrome), title:(.*YouTube.*)"

      # Floating
      "float, class:^(org.pulseaudio.pavucontrol)$"
      "float, class:^(org.gnome.Calculator)$"
      "float, class:^(xdg-desktop-portal-gtk)$"
      
      # Geometry
      "center, class:^(org.pulseaudio.pavucontrol)$"
      "size 875 600, class:^(org.pulseaudio.pavucontrol)$"

      # Idle Inhibit
      "idleinhibit fullscreen, class:^(chromium|google-chrome)$"
      "idleinhibit fullscreen, class:^(vlc|mpv)$"
    ];

    # Layer rules - new syntax with match:namespace and values
    layerrule = [
      "blur on, match:namespace waybar"
      "blur on, match:namespace wofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 1, match:namespace wofi"
      "ignore_alpha 1, match:namespace notifications"
    ];
  };
}
