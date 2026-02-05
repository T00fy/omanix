{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Determine fallback based on what is enabled in the user config
  defaultBrowser = if config.programs.firefox.enable then "firefox.desktop" else "chromium.desktop"; # TODO need to add chromium as an option

  # Override the generic package with specific config for this user
  omanixScripts = pkgs.omanix-scripts.override {
    browserFallback = defaultBrowser;
    walker = inputs.walker.packages.${pkgs.system}.default;
  };

in
{
  home.packages = [
    omanixScripts

    pkgs.jq
    pkgs.procps

    pkgs.nautilus
    pkgs.chromium
    pkgs.firefox
  ];
}
