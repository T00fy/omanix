{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  config = lib.mkIf cfg.enable {
    # The lock-before-sleep user service (home-manager) holds a sleep delay
    # inhibitor and needs enough time to lock + confirm the surface is secure
    # before logind proceeds. The default 5s is too tight for PAM + Quickshell
    # lock; widen the bounded delay window to 15s.
    services.logind.settings.Login.InhibitDelayMaxSec = 15;
  };
}
