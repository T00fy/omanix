{ ... }:
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

      listener = [
        # # ─────────────────────────────────────────────────────────────────
        # # 2.5min (150s) -> Screensaver starts
        # # ─────────────────────────────────────────────────────────────────
        # {
        #   timeout = 150;
        #   on-timeout = "omanix-screensaver";
        #   on-resume = "omanix-screensaver-kill";
        # }

        # ─────────────────────────────────────────────────────────────────
        # 2.5min (150s) -> Brightness 10% (runs in parallel with screensaver)
        # ─────────────────────────────────────────────────────────────────
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }

        # ─────────────────────────────────────────────────────────────────
        # 5min (300s) -> Lock (screensaver gets killed by hyprlock taking over)
        # ─────────────────────────────────────────────────────────────────
        {
          timeout = 300;
          on-timeout = "omanix-screensaver-kill; loginctl lock-session";
        }

        # ─────────────────────────────────────────────────────────────────
        # 5.5min (330s) -> Screen Off (DPMS)
        # ─────────────────────────────────────────────────────────────────
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }

        # ─────────────────────────────────────────────────────────────────
        # 15min (900s) -> Suspend
        # ─────────────────────────────────────────────────────────────────
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
