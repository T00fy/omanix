{ config, lib, ... }:
let
  cfg = config.omanix.idle;

  # When the Quickshell omanix.idle service is active it owns the screensaver and
  # lock stages (shell.json idle.screensaver / idle.lock, driven by the same
  # omanix.idle.* options). hypridle is then reduced to the stages the shell has
  # no equivalent for — dim, dpms, suspend. Full hypridle retirement (and any
  # logind migration for those) is Q3-03.
  quickshellOwnsIdle = config.omanix.quickshell.enable;

  # Legacy hyprlock lock path — used only when the shell is not managing idle.
  # Start hyprlock in background, wait for it to grab focus, then kill screensaver.
  # The sleep prevents the window-close event from registering as user activity.
  hyprlockCmd = lib.concatStringsSep " " [
    "pidof hyprlock ||"
    "(hyprlock --immediate --no-fade-in &"
    "sleep 2;"
    "pkill -f 'omanix-screensaver')"
  ];

  lockCmd = if quickshellOwnsIdle then "omanix-system-lock" else hyprlockCmd;

  listeners = lib.flatten [
    (lib.optional (cfg.screensaver.enable && !quickshellOwnsIdle) {
      inherit (cfg.screensaver) timeout;
      on-timeout = "omanix-screensaver --logo ${cfg.screensaver.logo}";
    })

    (lib.optional cfg.dimScreen.enable {
      inherit (cfg.dimScreen) timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
    })

    (lib.optional (cfg.lock.enable && !quickshellOwnsIdle) {
      inherit (cfg.lock) timeout;
      on-timeout = lockCmd;
    })

    (lib.optional cfg.dpms.enable {
      inherit (cfg.dpms) timeout;
      on-timeout = ''hyprctl dispatch 'hl.dsp.dpms("off")' '';
      on-resume = ''hyprctl dispatch 'hl.dsp.dpms("on")' '';
    })

    (lib.optional cfg.suspend.enable {
      inherit (cfg.suspend) timeout;
      on-timeout = "systemctl suspend";
    })
  ];
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # On loginctl lock-session (e.g. before suspend) use whichever locker is
        # in charge: the shell lock plugin, or hyprlock in the legacy path.
        lock_cmd = lockCmd;
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = ''hyprctl dispatch 'hl.dsp.dpms("on")' '';
      }
      // lib.optionalAttrs (!quickshellOwnsIdle) {
        unlock_cmd = "pkill -f 'omanix-screensaver'";
      };
      listener = listeners;
    };
  };
}
