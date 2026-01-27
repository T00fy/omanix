{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # 2.5min -> Brightness 10%
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        # 5min -> Lock
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # 5.5min -> Screen Off
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # 15min -> Suspend
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
