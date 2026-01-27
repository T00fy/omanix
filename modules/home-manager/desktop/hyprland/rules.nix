{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Opacity (New Syntax)
      "opacity 0.97 0.9, match:class .*"
      "opacity 1 1, match:class ^(zoom|vlc|mpv|imv|org.gnome.NautilusPreviewer)$"
      "opacity 1 1, match:class ^(chromium|google-chrome), match:title .*YouTube.*"

      # Floating (New Syntax: float on)
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"
      "float on, match:class ^(org.gnome.Calculator)$"
      "float on, match:class ^(xdg-desktop-portal-gtk)$"
      
      # Geometry
      "center, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 875 600, match:class ^(org.pulseaudio.pavucontrol)$"

      # Idle Inhibit
      "idleinhibit fullscreen, match:class ^(chromium|google-chrome)$"
      "idleinhibit fullscreen, match:class ^(vlc|mpv)$"
    ];

    layerrule = [
      "blur, waybar"
      "blur, wofi"
      "blur, notifications"
      "ignorezero, wofi"
      "ignorezero, notifications"
    ];
  };
}
