{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.tailscale.operator = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "alice";
    description = ''
      Login name to grant operator over tailscaled, run declaratively as a
      oneshot after tailscaled starts (tailscale set --operator=<name>). This
      lets that user drive tailscale (Taildrop send/receive, the shell
      tailscale panel) without sudo, replacing the shell's runtime "authorize
      operator" prompt.

      Only takes effect when Tailscale is enabled on the host
      (services.tailscale.enable); it does not enable Tailscale itself. Null
      leaves the operator untouched.
    '';
  };

  config =
    lib.mkIf (cfg.enable && config.services.tailscale.enable && cfg.tailscale.operator != null)
      {
        systemd.services.omanix-tailscale-operator = {
          description = "Set Tailscale operator for ${cfg.tailscale.operator}";
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.services.tailscale.package}/bin/tailscale set --operator=${cfg.tailscale.operator}";
          };
        };
      };
}
