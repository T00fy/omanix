{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    # Use windowrulev2 for everything
    windowrulev2 = [
      # Opacity - new syntax: "RULE, PARAMS"
      "opacity 0.97 0.9, class:(.*)"
      "opacity 1.0 1.0, class:^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer)$"
      "opacity 1.0 1.0, class:^(chromium|google-chrome), title:(.*YouTube.*)"
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
    # Layer rules - new syntax with namespace
    layerrule = [
      "blur, waybar"
      "blur, wofi"
      "blur, notifications"
      "ignorealpha 0.5, waybar"
      "ignorealpha 0.5, wofi"
      "ignorealpha 0.5, notifications"
    ];
  };
}
