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

  monitorMap = lib.concatStringsSep ":" (
    lib.imap0 (idx: mon: "${mon.name}=${toString (idx * 10)}") config.omanix.monitors
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

    # ─────────────────────────────────────────────────────────────────
    # Script runtime dependencies (used by omanix-scripts at runtime)
    # ─────────────────────────────────────────────────────────────────
    jq
    procps
    grim
    slurp
    wl-clipboard
    libnotify
    hyprpicker
    wayfreeze
    libxkbcommon
    gawk
    gnused
    envsubst
    swaybg
    wlctl
    glow

    # ─────────────────────────────────────────────────────────────────
    # Media / hardware control (no useful HM modules for these)
    # ─────────────────────────────────────────────────────────────────
    playerctl
    brightnessctl
    wireplumber

    # ─────────────────────────────────────────────────────────────────
    # Screen recording toolchain
    # ─────────────────────────────────────────────────────────────────
    gpu-screen-recorder
    ffmpeg
    v4l-utils

    # ─────────────────────────────────────────────────────────────────
    # Standalone apps (no dedicated omanix module yet)
    # ─────────────────────────────────────────────────────────────────
    nautilus
    fastfetch
    chromium
    bitwarden-cli
    localsend
    bluetui
    networkmanagerapplet
  ];
}
