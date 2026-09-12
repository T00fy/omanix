{ config, lib, ... }: {
  wayland.windowManager.hyprland.settings = {
    env = [
      { _args = [ "XCURSOR_THEME" "Adwaita" ]; }
      { _args = [ "XCURSOR_SIZE" "24" ]; }
      { _args = [ "HYPRCURSOR_THEME" "Adwaita" ]; }
      { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
      { _args = [ "GDK_BACKEND" "wayland,x11,*" ]; }
      { _args = [ "QT_QPA_PLATFORM" "wayland;xcb" ]; }
      { _args = [ "SDL_VIDEODRIVER" "wayland" ]; }
      { _args = [ "CLUTTER_BACKEND" "wayland" ]; }
      { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
      { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
      { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
      { _args = [ "GTK_THEME" "Adwaita-dark" ]; }
      { _args = [ "GTK_IM_MODULE" "" ]; }
    ] ++ lib.optional config.omanix.quickshell.enable {
      _args = [ "OMANIX_PATH" "${config.omanix.quickshell.package}/share/omanix" ];
    };
  };
}
