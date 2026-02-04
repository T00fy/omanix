{ config, lib, ... }:
let
  cfg = config.omanix.idle;

  listeners = lib.flatten [
    # Screensaver
    (lib.optional cfg.screensaver.enable {
      inherit (cfg.screensaver) timeout;
      on-timeout = "omanix-screensaver --logo ${cfg.screensaver.logo}";
    })

    # Dim screen
    (lib.optional cfg.dimScreen.enable {
      inherit (cfg.dimScreen) timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
    })

    # Lock screen
    (lib.optional cfg.lock.enable {
      inherit (cfg.lock) timeout;
      on-timeout = "pkill -f 'omanix-screensaver'; pidof hyprlock || hyprlock";
    })

    # DPMS (screen off)
    (lib.optional cfg.dpms.enable {
      inherit (cfg.dpms) timeout;
      on-timeout = "hyprctl dispatch dpms off";
      on-resume = "hyprctl dispatch dpms on";
    })

    # Suspend
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
        lock_cmd = "pkill -f 'omanix-screensaver'; pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        unlock_cmd = "pkill -f 'omanix-screensaver'";
      };

      listener = listeners;
    };
  };
}
