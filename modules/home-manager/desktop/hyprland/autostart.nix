{ config, lib, pkgs, ... }:
let
  inherit (config.omanix.activeTheme.assets) wallpaper;
  cfg = config.omanix;
  qs = cfg.quickshell.enable;

  autostartCmds =
    # Propagate session env (incl. OMANIX_PATH) to systemd/dbus.
    [ "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XCURSOR_THEME XCURSOR_SIZE GDK_SCALE HYPRCURSOR_THEME HYPRCURSOR_SIZE OMANIX_PATH" ]
    # The Quickshell desktop shell hosts bar/notifications/osd/polkit/clipboard/background.
    ++ lib.optional qs "${pkgs.quickshell}/bin/quickshell -n -p $OMANIX_PATH/shell"
    # Old stack — only when the shell is not running (it owns these otherwise).
    ++ lib.optionals (!qs) [
      "swayosd-server"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill"
    ]
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
