{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.security.lock = {
    enable = lib.mkEnableOption "in-shell lock screen PAM services" // {
      default = true;
      description = ''
        Declare the PAM services the Quickshell lock plugin (omanix.lock)
        authenticates against. The plugin refuses to lock unless
        /etc/pam.d/omanix-lock-password exists, so this must be declared for
        the shell lock to work.
      '';
    };

    fingerprint.enable = lib.mkOption {
      type = lib.types.bool;
      default = config.services.fprintd.enable;
      defaultText = lib.literalExpression "config.services.fprintd.enable";
      description = ''
        Declare the omanix-lock-fingerprint PAM service so the lock plugin can
        offer fingerprint unlock. Only meaningful once a reader is enrolled via
        fprintd; when disabled the service is absent and the plugin cleanly
        reports no fingerprint (no hard failure).
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.security.lock.enable) {
    # Password unlock — standard unix auth stack (pam_unix), same as login.
    # fprintAuth is forced off so the plugin's password context stays
    # password-only; fingerprint is a separate service/context below.
    security.pam.services.omanix-lock-password = {
      fprintAuth = false;
    };

    # Fingerprint unlock — separate service the plugin's fingerprint context
    # targets. Declared only when fprintd is enabled.
    security.pam.services.omanix-lock-fingerprint = lib.mkIf cfg.security.lock.fingerprint.enable {
      unixAuth = false;
      fprintAuth = true;
    };
  };
}
