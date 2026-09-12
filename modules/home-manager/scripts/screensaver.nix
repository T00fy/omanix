{ pkgs, ... }:
{
  systemd.user.services.omanix-screensaver-cleanup = {
    Unit = {
      Description = "Cleanup Omanix screensaver on shutdown";
      Before = [
        "shutdown.target"
        "reboot.target"
        "halt.target"
      ];
    };
    Service = {
      Type = "oneshot";
      # Kill ttfx and its terminals; `true` keeps the oneshot green when nothing
      # is running (pkill exits non-zero on no match).
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.procps}/bin/pkill -x ttfx; ${pkgs.procps}/bin/pkill -f \"[o]rg.omanix.screensaver\"; true'";
      TimeoutStartSec = "2s";
    };
    Install = {
      WantedBy = [ "shutdown.target" ];
    };
  };
}
