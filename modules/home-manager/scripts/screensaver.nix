{ pkgs, ... }:
{
  home.packages = [ pkgs.omanix-screensaver ];

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
      ExecStart = "${pkgs.procps}/bin/pkill -f 'omanix-screensaver'";
      TimeoutStartSec = "2s";
    };
    Install = {
      WantedBy = [ "shutdown.target" ];
    };
  };
}
