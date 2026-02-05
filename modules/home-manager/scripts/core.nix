{
  pkgs,
  inputs,
  config,
  omanixLib,
  ...
}:
let
  # Determine fallback based on what is enabled in the user config
  defaultBrowser = if config.programs.firefox.enable then "firefox.desktop" else "chromium.desktop";

  availableThemes = builtins.attrNames omanixLib.themes;
  themeListFormatted = builtins.concatStringsSep "\\n" (map (t: "- ${t}") availableThemes);

  themesJson = pkgs.writeText "omanix-themes.json" (
    builtins.toJSON (builtins.mapAttrs (_name: val: val.assets.wallpapers) omanixLib.themes)
  );

  docStylePreview = pkgs.writeText "style-preview.md" (
    builtins.readFile ../../../docs/style-preview.md
  );
  docStyleOverride = pkgs.writeText "style-override.md" (
    builtins.readFile ../../../docs/style-override.md
  );
  docStyleGeneral = ../../../docs/style.md;
  docsDir = ../../../docs;

  # Override the generic package with specific config for this user
  omanixScripts = pkgs.omanix-scripts.override {
    browserFallback = defaultBrowser;
    walker = inputs.walker.packages.${pkgs.system}.default;
    inherit themesJson docStylePreview docStyleOverride docStyleGeneral docsDir themeListFormatted;
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
