{ config, lib, pkgs, ... }:
let
  inherit (config.omanix.activeTheme.assets) wallpaper;
  cfg = config.omanix;

  extraExecLines = lib.concatMapStringsSep "\n" (cmd: ''      hl.exec_cmd(${builtins.toJSON cmd})'') cfg.hyprland.extraAutostart;
in
{
  options.omanix.hyprland.extraAutostart = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "fcitx5" ];
    description = ''
      Extra commands to run once when Hyprland starts, in addition to the
      Omanix defaults. Each entry is passed to hl.exec_cmd on hyprland.start.

      Useful for input methods, personal daemons, or anything you'd normally
      put in an exec-once. For example, CJK users can start fcitx5:

        omanix.hyprland.extraAutostart = [ "fcitx5" ];

      (fcitx5 itself must still be installed and configured separately, e.g.
      via i18n.inputMethod in your own configuration.)
    '';
  };

  config = {
    wayland.windowManager.hyprland.extraConfig = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE GDK_SCALE HYPRCURSOR_THEME HYPRCURSOR_SIZE OMANIX_PATH")
${lib.optionalString cfg.quickshell.enable ''        hl.exec_cmd("${pkgs.quickshell}/bin/quickshell -n -p $OMANIX_PATH/shell")
''}        hl.exec_cmd("mako")
        hl.exec_cmd("swayosd-server")
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
        hl.exec_cmd("${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill")
${extraExecLines}
      end)
    '';
  };
}
