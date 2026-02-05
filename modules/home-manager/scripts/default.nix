{
  pkgs,
  inputs,
  config,
  omanixLib,
  ...
}:
let
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

  omanixScripts = pkgs.omanix-scripts.override {
    browserFallback = defaultBrowser;
    walker = inputs.walker.packages.${pkgs.system}.default;
    inherit themesJson docStylePreview docStyleOverride docStyleGeneral docsDir themeListFormatted;
  };
in
{
  imports = [
    ./screensaver.nix
  ];

  home.packages = with pkgs; [
    omanixScripts

    # Core
    jq
    procps
    nautilus
    chromium
    firefox

    # Media
    playerctl
    brightnessctl
    wireplumber
    pavucontrol

    # System
    satty
    wayfreeze
    grim
    slurp
    wl-clipboard
    libnotify
    hyprpicker
    blueman
    bitwarden-cli

    # Menu
    networkmanagerapplet
    libxkbcommon
    gawk
    gnused
    localsend
    impala
    bluetui
    glow
    envsubst
    swaybg
  ];
}
