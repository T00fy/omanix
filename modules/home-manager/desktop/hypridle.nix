{ config, lib, ... }:
let
  cfg = config.omanix.idle;

  # The Quickshell omanix.idle service owns the screensaver and lock stages
  # (shell.json idle.screensaver / idle.lock, driven by the same omanix.idle.*
  # options). hypridle is reduced to the stages the shell has no equivalent for
  # — dim, dpms, suspend.
  listeners = lib.flatten [
    (lib.optional cfg.dimScreen.enable {
      inherit (cfg.dimScreen) timeout;
      on-timeout = "brightnessctl -s set ${toString cfg.dimScreen.brightness}";
      on-resume = "brightnessctl -r";
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
        # On loginctl lock-session (e.g. before suspend) lock via the shell.
        lock_cmd = "omanix-system-lock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = ''hyprctl dispatch 'hl.dsp.dpms("on")' '';
      };
      listener = listeners;
    };
  };
}
