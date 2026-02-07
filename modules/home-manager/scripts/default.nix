{
  pkgs,
  inputs,
  config,
  lib,
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
  screensaverLogo = config.omanix.idle.screensaver.logo;

  gapsOuter = toString config.omanix.hyprland.gaps.outer;
  gapsInner = toString config.omanix.hyprland.gaps.inner;
  borderSize = toString config.omanix.hyprland.border.size;

  activeTheme = config.omanix.activeTheme;
  wallpaperList = builtins.concatStringsSep "\n" (map toString activeTheme.assets.wallpapers);

  # Generate monitor map for omanix-workspace: "DP-2=0:HDMI-A-2=10"
  monitorMap = lib.concatStringsSep ":" (
    lib.imap0 (idx: mon:
      "${mon.name}=${toString (idx * 10)}"
    ) config.omanix.monitors
  );

  omanixScripts = pkgs.omanix-scripts.override {
    browserFallback = defaultBrowser;
    walker = inputs.walker.packages.${pkgs.system}.default;
    inherit
      themesJson
      docStylePreview
      docStyleOverride
      docStyleGeneral
      docsDir
      themeListFormatted
      screensaverLogo
      ;
    inherit
      gapsOuter
      gapsInner
      borderSize
      wallpaperList
      monitorMap
      ;
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
    btop
    lazydocker

    # Screen recording
    gpu-screen-recorder
    ffmpeg
    v4l-utils

    # Menu
    networkmanagerapplet
    libxkbcommon
    gawk
    gnused
    localsend
    bluetui
    wlctl
    glow
    envsubst
    swaybg
  ];
}
