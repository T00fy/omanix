{
  config,
  lib,
  ...
}:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;

  # The managed-policy color is the active theme's background, matching
  # omarchy's chromium.theme = {{ background_rgb }}.
  background = omanixLib.themes.${cfg.theme}.colors.background;

  policyJson = builtins.toJSON {
    BrowserThemeColor = background;
    BrowserColorScheme = "device";
  };

  # Chromium-family enterprise managed-policy roots. Written declaratively via
  # environment.etc from the palette — this replaces omarchy's privileged
  # runtime script + passwordless-sudoers rule entirely (no /etc write at
  # runtime, no pkexec). /etc is read-only under Nix, so browser color tracks
  # only the declared omanix.theme (a runtime omanix-theme-set does not retint
  # browsers); this is expected and documented on the option.
  policyPaths = [
    "chromium/policies/managed/color.json"
    "opt/chrome/policies/managed/color.json"
    "opt/edge/policies/managed/color.json"
    "brave/policies/managed/color.json"
  ];
in
{
  options.omanix.browserPolicy.enable =
    lib.mkEnableOption "the declarative Chromium-family theme-color managed policy"
    // {
      default = false;
      description = ''
        Whether to write a managed browser policy that tints
        Chromium/Chrome/Edge/Brave to the active {option}`omanix.theme`
        background color, via {option}`environment.etc`. Off by default: a
        managed policy is *mandatory* for every profile of the affected
        browsers.

        Declarative only — the color changes on `nixos-rebuild`, not at runtime
        (`/etc` is read-only under Nix, so `omanix-theme-set` does not retint
        browsers). Replaces omarchy's privileged runtime writer + sudoers rule.
      '';
    };

  config = lib.mkIf (cfg.enable && cfg.browserPolicy.enable) {
    environment.etc = lib.genAttrs policyPaths (_: { text = policyJson; });
  };
}
