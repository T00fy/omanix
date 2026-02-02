{ config, lib, ... }:
let
  cfg = config.omanix.idle;

  logoPath = "${config.home.homeDirectory}/omanix/assets/branding/logo.txt";

  listeners = lib.flatten [
    # Screensaver - no on-resume needed, it handles its own exit
    (lib.optional cfg.screensaver.enable {
      timeout = cfg.screensaver.timeout;
      on-timeout = "omanix-screensaver --logo ${logoPath}";
    })

    # Dim screen
    (lib.optional cfg.dimScreen.enable {
      timeout = cfg.dimScreen.timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
    })

    # Lock screen - kill screensaver before locking
    (lib.optional cfg.lock.enable {
      timeout = cfg.lock.timeout;
      on-timeout = "pkill -f 'omanix-screensaver'; pidof hyprlock || hyprlock";
    })

    # DPMS (screen off)
    (lib.optional cfg.dpms.enable {
      timeout = cfg.dpms.timeout;
      on-timeout = "hyprctl dispatch dpms off";
      on-resume = "hyprctl dispatch dpms on";
    })

    # Suspend
    (lib.optional cfg.suspend.enable {
      timeout = cfg.suspend.timeout;
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
