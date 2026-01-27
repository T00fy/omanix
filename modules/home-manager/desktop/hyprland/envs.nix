{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    env = [
      # Cursor - Explicitly force it
      "XCURSOR_THEME,Adwaita"
      "XCURSOR_SIZE,24"
      "HYPRCURSOR_THEME,Adwaita"
      "HYPRCURSOR_SIZE,24"

      # Toolkit Backends
      "GDK_BACKEND,wayland,x11,*"
      "QT_QPA_PLATFORM,wayland;xcb"
      "SDL_VIDEODRIVER,wayland"
      "CLUTTER_BACKEND,wayland"

      # XDG
      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "XDG_SESSION_DESKTOP,Hyprland"
      
      # Theming
      "GTK_THEME,Adwaita-dark"
    ];
  };
}
