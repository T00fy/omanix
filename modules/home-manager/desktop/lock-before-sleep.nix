{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

let
  # Gate on the NixOS-side lock PAM services when running as a NixOS module:
  # without /etc/pam.d/omanix-lock-password the shell lock never reaches
  # `secure`, so locking before sleep is pointless. Standalone Home Manager
  # can't see osConfig — assume enabled and let the user own their PAM stack.
  lockEnabled =
    if (osConfig != null && osConfig ? omanix && osConfig.omanix ? security) then
      osConfig.omanix.enable && osConfig.omanix.security.lock.enable
    else
      true;

  systemLock = "${config.omanix.scripts.package}/bin/omanix-system-lock";
  shell = "${config.omanix.quickshell.package}/bin/omanix-shell";

  # The watcher: blocks on the system bus for one logind PrepareForSleep(true),
  # locks, then waits for the lock surface to actually report secure before
  # returning. It runs under a sleep delay inhibitor (see ExecStart), so logind
  # holds off suspend until it exits — capped by InhibitDelayMaxSec (15s, set in
  # modules/nixos/idle.nix). The poll is capped below that so we never overrun.
  lockWatcher = pkgs.writeShellApplication {
    name = "omanix-lock-before-sleep-watch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dbus
      pkgs.jq
    ];
    text = ''
      while read -r line; do
        case "$line" in
          *"boolean true"*)
            ${systemLock} || true
            for _ in $(seq 1 130); do
              if [ "$(${shell} lock status 2>/dev/null | jq -r '.secure' 2>/dev/null)" = "true" ]; then
                break
              fi
              sleep 0.1
            done
            break
            ;;
        esac
      done < <(dbus-monitor --system \
        "type=signal,interface=org.freedesktop.login1.Manager,member=PrepareForSleep")
    '';
  };

  # Grab the delay inhibitor, then hand off to the watcher. When the watcher
  # exits (post-lock) the inhibitor releases and suspend proceeds with the
  # machine already secure. Restart=always re-arms for the next cycle.
  lockBeforeSleep = pkgs.writeShellApplication {
    name = "omanix-lock-before-sleep";
    runtimeInputs = [
      pkgs.systemd
      lockWatcher
    ];
    text = ''
      exec systemd-inhibit --what=sleep --mode=delay \
        --who=omanix --why="Lock before sleep" \
        omanix-lock-before-sleep-watch
    '';
  };
in
{
  config = lib.mkIf (config.omanix.quickshell.enable && lockEnabled) {
    systemd.user.services.omanix-lock-before-sleep = {
      Unit = {
        Description = "Omanix lock-before-sleep inhibitor";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lockBeforeSleep}/bin/omanix-lock-before-sleep";
        Restart = "always";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
