{ config, lib, ... }:
let
  cfg = config.omanix.idle;
  
  # Build listener list conditionally based on enabled options
  listeners = lib.flatten [
    # Screensaver
    (lib.optional cfg.screensaver.enable {
      timeout = cfg.screensaver.timeout;
      on-timeout = "omanix-screensaver";
      on-resume = "omanix-screensaver-kill";
    })

    # Dim screen
    (lib.optional cfg.dimScreen.enable {
      timeout = cfg.dimScreen.timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
    })

    # Lock screen
    (lib.optional cfg.lock.enable {
      timeout = cfg.lock.timeout;
      on-timeout = "omanix-screensaver-kill; loginctl lock-session";
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
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        # Kill screensaver when lock activates
        unlock_cmd = "omanix-screensaver-kill";
      };

      listener = listeners;
    };
  };
}
