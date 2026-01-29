{ lib, ... }:
let
  # List of applications to hide from the launcher.
  # This matches the upstream Omarchy 'applications/hidden' directory.
  appsToHide = [
    # Fcitx / Input Method clutter
    "org.fcitx.Fcitx5"
    "fcitx5-configtool"
    "fcitx5-wayland-launcher"
    "kbd-layout-viewer5"
    "kcm_fcitx5"
    "org.fcitx.fcitx5-config-qt"
    "org.fcitx.fcitx5-migrator"
    "org.fcitx.fcitx5-qt5-gui-wrapper"
    "org.fcitx.fcitx5-qt6-gui-wrapper"

    # Network / VNC / SSH clutter
    "avahi-discover"
    "bssh"
    "bvnc"
    
    # Dev / System clutter
    "cmake-gui"
    "qv4l2"
    "qvidcap"
    "uuctl"
    "xgps"
    "xgpsspeed"
    "cups"
    
    # Java / Electron clutter
    "java-java-openjdk"
    "jconsole-java-openjdk"
    "jshell-java-openjdk"
    "electron34"
    "electron36"
    "electron37"
    
    # KDE / Qt clutter
    "kcm_kaccounts"
    "kvantummanager"
    
    # Apps that Omarchy replaces with TUIs or specialized wrappers
    "btop" 
  ];
in
{
  # Generate a hidden .desktop file for every app in the list
  xdg.dataFile = lib.genAttrs 
    (map (name: "applications/${name}.desktop") appsToHide)
    (_: { text = "[Desktop Entry]\nHidden=true"; });
}
