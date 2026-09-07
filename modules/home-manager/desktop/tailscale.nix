{
  config,
  lib,
  ...
}:

let
  cfg = config.omanix.tailscale;
in
{
  options.omanix.tailscale.taildrop.enable = lib.mkEnableOption ''
    the Taildrop receiver.

    Runs omanix-tailscale-receive as a user service: incoming Taildrop files
    are saved to ~/Downloads (rename-on-conflict) and announced with a
    notification (image preview for images, click to open). Sending is always
    available via omanix-tailscale-send / the shell tailscale panel; only the
    receiver is gated here. Tailscale itself is host-provided
    (services.tailscale.enable); set omanix.tailscale.operator (NixOS) so the
    user can drive tailscale without sudo'';

  config = lib.mkIf cfg.taildrop.enable {
    systemd.user.services.omanix-tailscale-receive = {
      Unit = {
        Description = "Omanix Taildrop receiver";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${config.omanix.scripts.package}/bin/omanix-tailscale-receive";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
