{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;

  autostartCmds =
    # Propagate session env (incl. OMANIX_PATH) to systemd/dbus.
    [ "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE GDK_SCALE HYPRCURSOR_THEME HYPRCURSOR_SIZE OMANIX_PATH" ]
    # The Quickshell desktop shell hosts bar/notifications/osd/polkit/clipboard/background.
    ++ lib.optional cfg.quickshell.enable "${pkgs.quickshell}/bin/quickshell -n -p $OMANIX_PATH/shell"
    ++ cfg.hyprland.extraAutostart;

  execLines = lib.concatMapStringsSep "\n"
    (cmd: "        hl.exec_cmd(${builtins.toJSON cmd})") autostartCmds;
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
      ${execLines}
      end)
    '';
  };
}
