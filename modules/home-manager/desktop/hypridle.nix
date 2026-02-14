{ config, lib, ... }:
let
  cfg = config.omanix.idle;

  # Start hyprlock in background, wait for it to grab focus, then kill screensaver.
  # The sleep prevents the window-close event from registering as user activity.
  lockCmd = lib.concatStringsSep " " [
    "pidof hyprlock ||"
    "(hyprlock --immediate --no-fade-in &"
    "sleep 2;"
    "pkill -f 'omanix-screensaver')"
  ];

  listeners = lib.flatten [
    (lib.optional cfg.screensaver.enable {
      inherit (cfg.screensaver) timeout;
      on-timeout = "omanix-screensaver --logo ${cfg.screensaver.logo}";
    })

    (lib.optional cfg.dimScreen.enable {
      inherit (cfg.dimScreen) timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
    })

    (lib.optional cfg.lock.enable {
      inherit (cfg.lock) timeout;
      on-timeout = lockCmd;
    })

    (lib.optional cfg.dpms.enable {
      inherit (cfg.dpms) timeout;
      on-timeout = "hyprctl dispatch dpms off";
      on-resume = "hyprctl dispatch dpms on";
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
        lock_cmd = lockCmd;
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        unlock_cmd = "pkill -f 'omanix-screensaver'";
      };
      listener = listeners;
    };
  };
}
