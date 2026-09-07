{
  pkgs,
  inputs,
  config,
  lib,
  omanixLib,
  osConfig ? null,
  ...
}:
let
  # omanix-scale (runtime Moonlight UI-scale toggle) needs the same monitor
  # scale-change command Sunshine's own prep-cmd uses, so a menu-triggered
  # toggle and a Sunshine-triggered one can never disagree — see
  # pkgs/omanix-scripts/src/omanix-scale.sh. osConfig is only present when
  # running under NixOS with home-manager as a module (not standalone), same
  # pattern as modules/home-manager/theme/default.nix.
  hasScaledDesktop =
    osConfig != null
    && osConfig ? omanix
    && osConfig.omanix ? sunshine
    && osConfig.omanix.sunshine.scaledDesktop.enable;
  scaledDesktop = if hasScaledDesktop then osConfig.omanix.sunshine.scaledDesktop else null;

  # omanix-scale's dummy-display toggle (--dummy-on/--dummy-off) needs the
  # same osConfig bridge as scaledDesktop above, so a menu-triggered toggle
  # and Sunshine's prep-cmd-triggered one can never disagree — see
  # modules/nixos/sunshine.nix for the equivalent NixOS-level instance and
  # pkgs/omanix-scripts/src/omanix-scale.sh for the runtime logic.
  hasDummyDisplay =
    osConfig != null
    && osConfig ? omanix
    && osConfig.omanix ? sunshine
    && osConfig.omanix.sunshine.dummyDisplay.enable;
  dummyDisplay = if hasDummyDisplay then osConfig.omanix.sunshine.dummyDisplay else null;

  # Shared with the NixOS-level instance (modules/nixos/sunshine.nix) via
  # lib/dummy-display.nix, so the two instances can never compute a
  # different default position/env-string.
  dummyDisplayPosition =
    if dummyDisplay == null then
      ""
    else
      omanixLib.dummyDisplay.resolvePosition {
        position = dummyDisplay.position;
        realMonitors = dummyDisplay.realMonitors;
      };

  dummyDisplayRealMonitorsEnv =
    if dummyDisplay == null then "" else omanixLib.dummyDisplay.realMonitorsEnv dummyDisplay.realMonitors;
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

  monitorMap = lib.concatStringsSep ":" (
    lib.imap0 (idx: mon: "${mon.name}=${toString (idx * 10)}") config.omanix.monitors
  );

  omanixScripts = pkgs.omanix-scripts.override {
    walker = inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default;
    terminalWrapper = config.omanix.terminal.wrapper;
    shellDefaults = config.omanix.quickshell.declaredBaseFile;
    quickshellThemesDir = config.omanix.quickshell.themesDir;
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
      monitorMap
      ;
    walkerWidth = toString config.omanix.walker.width;
    walkerHeight = toString config.omanix.walker.height;
    walkerScaledWidth = toString config.omanix.walker.scaledWidth;
    walkerScaledHeight = toString config.omanix.walker.scaledHeight;
    menuWidth = toString config.omanix.menu.width;
    menuMaxHeight = toString config.omanix.menu.maxHeight;
    scaledDesktopMonitor = if scaledDesktop != null then scaledDesktop.monitor else "";
    scaledDesktopMode = if scaledDesktop != null then scaledDesktop.mode else "";
    scaledDesktopPosition = if scaledDesktop != null then scaledDesktop.position else "";
    scaledDesktopScale = if scaledDesktop != null then scaledDesktop.scale else "";
    scaledDesktopRevertScale = if scaledDesktop != null then scaledDesktop.revertScale else "";
    scaledDesktopSensitivity = if scaledDesktop != null then scaledDesktop.sensitivity else "";
    scaledDesktopRevertSensitivity =
      if scaledDesktop != null then scaledDesktop.revertSensitivity else "";
    scaledDesktopCursorSize = if scaledDesktop != null then toString scaledDesktop.cursorSize else "";
    scaledDesktopRevertCursorSize =
      if scaledDesktop != null then toString scaledDesktop.revertCursorSize else "";
    dummyDisplayConnector = if dummyDisplay != null then dummyDisplay.connector else "";
    dummyDisplayMode = if dummyDisplay != null then dummyDisplay.mode else "";
    inherit dummyDisplayPosition;
    dummyDisplayScale = if dummyDisplay != null then dummyDisplay.scale else "";
    dummyDisplaySensitivity = if dummyDisplay != null then dummyDisplay.sensitivity else "";
    dummyDisplayRevertSensitivity = if dummyDisplay != null then dummyDisplay.revertSensitivity else "";
    dummyDisplayCursorSize = if dummyDisplay != null then toString dummyDisplay.cursorSize else "";
    dummyDisplayRevertCursorSize =
      if dummyDisplay != null then toString dummyDisplay.revertCursorSize else "";
    dummyDisplayRealMonitors = dummyDisplayRealMonitorsEnv;
  };
in
{
  imports = [
    ./screensaver.nix
  ];

  home.packages = with pkgs; [
    omanixScripts
    config.omanix.browser.package

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
    wl-screenrec

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
