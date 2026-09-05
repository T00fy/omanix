{
  lib,
  stdenv,
  makeWrapper,
  bash,
  xdg-utils,
  hyprland,
  jq,
  coreutils,
  ghostty,
  terminalWrapper ? ghostty,
  procps,
  systemd,
  walker,
  gawk,
  gnugrep,
  gnused,
  quickshell,
  libxkbcommon,
  libnotify,
  swaybg,
  envsubst,
  glow,
  pavucontrol,
  hyprpicker,
  waybar,
  wayfreeze,
  grim,
  slurp,
  wl-clipboard,
  wtype,
  hyprlock,
  bitwarden-cli,
  pulseaudio,
  swayosd,
  wl-screenrec,
  hypridle,
  localsend,
  fzf,
  omanix-screensaver,
  # Data files injected by the module
  themesJson ? null,
  docStylePreview ? null,
  docStyleOverride ? null,
  docStyleGeneral ? null,
  docsDir ? null,
  themeListFormatted ? "",
  screensaverLogo ? null,
  # Hyprland visual defaults for gap toggling
  gapsOuter ? "10",
  gapsInner ? "5",
  borderSize ? "2",
  # Newline-separated wallpaper paths for cycling
  wallpaperList ? "",
  monitorMap ? "",
  walkerWidth ? "644",
  walkerHeight ? "300",
  walkerScaledWidth ? "805",
  walkerScaledHeight ? "375",
  menuWidth ? "295",
  menuMaxHeight ? "630",
  # omanix.sunshine.scaledDesktop settings (from osConfig), empty when unset
  scaledDesktopMonitor ? "",
  scaledDesktopMode ? "",
  scaledDesktopPosition ? "",
  scaledDesktopScale ? "",
  scaledDesktopRevertScale ? "",
  scaledDesktopSensitivity ? "",
  scaledDesktopRevertSensitivity ? "",
  scaledDesktopCursorSize ? "",
  scaledDesktopRevertCursorSize ? "",
  # omanix.sunshine.dummyDisplay settings (from osConfig), empty when unset
  dummyDisplayConnector ? "",
  dummyDisplayMode ? "",
  dummyDisplayPosition ? "",
  dummyDisplayScale ? "",
  dummyDisplaySensitivity ? "",
  dummyDisplayRevertSensitivity ? "",
  dummyDisplayCursorSize ? "",
  dummyDisplayRevertCursorSize ? "",
  # Newline-separated "name|mode|position|scale" lines for the real monitors
  # to disable/re-enable around the dummy display, empty when unset
  dummyDisplayRealMonitors ? "",
}:

let
  # Helper: generate --set flags from an attrset, skipping null values
  mkEnvFlags =
    envs:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (k: v: if v != null then ''--set ${k} "${v}"'' else "") envs
    );

  # ═══════════════════════════════════════════════════════════════════
  # Script Definitions
  # Each entry defines: name, runtime deps, env vars, and whether
  # it needs $out/bin on PATH (for calling sibling scripts).
  # ═══════════════════════════════════════════════════════════════════
  scripts = [
    {
      name = "omanix-shell";
      deps = [
        bash
        coreutils
        gnugrep
        quickshell
      ];
    }
    {
      name = "omanix-osd";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
    }
    {
      # Screensaver launcher for the omanix.idle service. Bakes the declared
      # logo path (omanix.idle.screensaver.logo) so the bare command the shell
      # invokes still honors it.
      name = "omanix-launch-screensaver";
      deps = [
        bash
        coreutils
        omanix-screensaver
      ];
      envs = lib.optionalAttrs (screensaverLogo != null) {
        OMANIX_SCREENSAVER_LOGO = "${screensaverLogo}";
      };
    }
    {
      # Lock action for the omanix.idle service (and hypridle lock_cmd) — drives
      # the omanix.lock shell plugin.
      name = "omanix-system-lock";
      deps = [
        bash
        coreutils
        procps
      ];
      selfPath = true;
    }
    {
      # Wake handler for the omanix.idle service and omanix.lock plugin.
      name = "omanix-system-wake";
      deps = [
        bash
        coreutils
        hyprland
      ];
    }
    {
      name = "omanix-launch-or-focus";
      deps = [
        bash
        hyprland
        jq
        coreutils
      ];
    }
    {
      name = "omanix-hyprland-focus-app";
      deps = [
        bash
        hyprland
        jq
        coreutils
      ];
    }
    {
      name = "omanix-launch-tui";
      deps = [
        bash
        terminalWrapper
        coreutils
      ];
    }
    {
      name = "omanix-launch-or-focus-tui";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }
    {
      name = "omanix-cmd-terminal-cwd";
      deps = [
        bash
        hyprland
        jq
        procps
        coreutils
      ];
    }
    {
      name = "omanix-launch-walker";
      deps = [
        bash
        procps
        systemd
        coreutils
      ];
      envs = {
        WALKER_BIN = "${walker}/bin/walker";
        OMANIX_WALKER_WIDTH = walkerWidth;
        OMANIX_WALKER_HEIGHT = walkerHeight;
        OMANIX_WALKER_SCALED_WIDTH = walkerScaledWidth;
        OMANIX_WALKER_SCALED_HEIGHT = walkerScaledHeight;
      };
    }
    {
      name = "omanix-scale";
      deps = [
        bash
        procps
        coreutils
        libnotify
        hyprland
        jq
      ];
      envs = {
        OMANIX_SCALE_MONITOR = scaledDesktopMonitor;
        OMANIX_SCALE_MODE = scaledDesktopMode;
        OMANIX_SCALE_POSITION = scaledDesktopPosition;
        OMANIX_SCALE_FACTOR = scaledDesktopScale;
        OMANIX_SCALE_REVERT_FACTOR = scaledDesktopRevertScale;
        OMANIX_SCALE_SENSITIVITY = scaledDesktopSensitivity;
        OMANIX_SCALE_REVERT_SENSITIVITY = scaledDesktopRevertSensitivity;
        OMANIX_SCALE_CURSOR_SIZE = scaledDesktopCursorSize;
        OMANIX_SCALE_REVERT_CURSOR_SIZE = scaledDesktopRevertCursorSize;
        OMANIX_DUMMY_DISPLAY_CONNECTOR = dummyDisplayConnector;
        OMANIX_DUMMY_DISPLAY_MODE = dummyDisplayMode;
        OMANIX_DUMMY_DISPLAY_POSITION = dummyDisplayPosition;
        OMANIX_DUMMY_DISPLAY_SCALE = dummyDisplayScale;
        OMANIX_DUMMY_DISPLAY_SENSITIVITY = dummyDisplaySensitivity;
        OMANIX_DUMMY_DISPLAY_REVERT_SENSITIVITY = dummyDisplayRevertSensitivity;
        OMANIX_DUMMY_DISPLAY_CURSOR_SIZE = dummyDisplayCursorSize;
        OMANIX_DUMMY_DISPLAY_REVERT_CURSOR_SIZE = dummyDisplayRevertCursorSize;
        OMANIX_DUMMY_DISPLAY_REAL_MONITORS = dummyDisplayRealMonitors;
      };
    }
    {
      name = "omanix-smart-delete";
      deps = [
        bash
        hyprland
        jq
      ];
    }
    {
      name = "omanix-menu";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
    }
    {
      name = "omanix-menu-emoji";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }
    {
      name = "omanix-menu-emoji-insert";
      deps = [
        bash
        coreutils
        wl-clipboard
        wtype
      ];
    }
    {
      name = "omanix-clipboard-open";
      deps = [
        bash
        coreutils
        jq
        xdg-utils
      ];
      selfPath = true;
    }
    {
      name = "omanix-clipboard-paste-text";
      deps = [
        bash
        coreutils
        jq
        wl-clipboard
        wtype
      ];
    }
    {
      name = "omanix-clipboard-paste-file";
      deps = [
        bash
        coreutils
        wl-clipboard
        wtype
      ];
    }
    {
      name = "omanix-menu-style";
      deps = [
        bash
        jq
        coreutils
        gnused
        envsubst
        swaybg
        terminalWrapper
        glow
      ];
      envs = {
        WALKER_BIN = "${walker}/bin/walker";
        OMANIX_THEMES_FILE = themesJson;
        OMANIX_DOC_STYLE_PREVIEW = docStylePreview;
        OMANIX_DOC_STYLE_OVERRIDE = docStyleOverride;
      };
      selfPath = true;
    }
    {
      name = "omanix-menu-keybindings";
      deps = [
        bash
        gawk
        libxkbcommon
        hyprland
        jq
        gnused
        coreutils
      ];
      selfPath = true;
    }
    {
      name = "omanix-show-style-help";
      deps = [
        bash
        coreutils
        gnused
        terminalWrapper
        glow
      ];
      envs = {
        OMANIX_DOC_STYLE = docStyleGeneral;
        OMANIX_THEME_LIST = themeListFormatted;
      };
    }
    {
      name = "omanix-show-setup-help";
      deps = [
        bash
        terminalWrapper
        glow
        coreutils
      ];
      envs = {
        OMANIX_DOCS_DIR = docsDir;
      };
    }
    {
      name = "omanix-cmd-logout";
      deps = [
        bash
        hyprland
        jq
        coreutils
      ];
    }
    {
      name = "omanix-cmd-screenshot";
      deps = [
        bash
        coreutils
        jq
        gawk
        procps
        hyprland
        grim
        slurp
        wl-clipboard
        wayfreeze
        libnotify
      ];
    }
    {
      name = "omanix-lock-screen";
      deps = [
        bash
        hyprland
        hyprlock
        libnotify
        bitwarden-cli
        procps
      ];
    }
    {
      name = "omanix-cmd-shutdown";
      deps = [
        bash
        hyprland
        jq
        coreutils
        systemd
      ];
    }
    {
      name = "omanix-cmd-reboot";
      deps = [
        bash
        hyprland
        jq
        coreutils
        systemd
      ];
    }
    {
      name = "omanix-cmd-audio-switch";
      deps = [
        bash
        jq
        hyprland
        pulseaudio
        swayosd
      ];
    }
    {
      name = "omanix-hyprland-window-close-all";
      deps = [
        bash
        hyprland
        jq
        coreutils
      ];
    }
    {
      name = "omanix-hyprland-window-pop";
      deps = [
        bash
        hyprland
        jq
      ];
    }
    {
      name = "omanix-hyprland-workspace-toggle-gaps";
      deps = [
        bash
        hyprland
        jq
      ];
      envs = {
        OMANIX_GAPS_OUTER = gapsOuter;
        OMANIX_GAPS_INNER = gapsInner;
        OMANIX_BORDER_SIZE = borderSize;
      };
    }
    {
      name = "omanix-theme-bg-next";
      deps = [
        bash
        coreutils
        swaybg
        libnotify
        procps
      ];
      envs = {
        OMANIX_WALLPAPERS = wallpaperList;
      };
    }
    {
      name = "omanix-toggle-idle";
      deps = [
        bash
        procps
        coreutils
        systemd
        libnotify
      ];
    }
    {
      name = "omanix-cmd-screenrecord";
      deps = [
        bash
        coreutils
        jq
        procps
        hyprland
        wl-screenrec
        pulseaudio
        libnotify
      ];
    }
    {
      name = "omanix-workspace";
      deps = [
        bash
        hyprland
        jq
      ];
      envs = {
        OMANIX_MONITOR_MAP = monitorMap;
      };
    }
    {
      name = "omanix-cmd-share";
      deps = [
        bash
        coreutils
        wl-clipboard
        libnotify
        systemd
        fzf
        localsend
      ];
    }
  ];

  # ═══════════════════════════════════════════════════════════════════
  # Generate install commands for a single script
  # ═══════════════════════════════════════════════════════════════════
  installScript =
    {
      name,
      deps,
      envs ? { },
      selfPath ? false,
      ...
    }:
    let
      binPath = (lib.optionalString selfPath "$out/bin:") + lib.makeBinPath deps;

      envFlags = mkEnvFlags envs;
    in
    ''
      cp src/${name}.sh $out/bin/${name}
      chmod +x $out/bin/${name}
      wrapProgram $out/bin/${name} \
        ${envFlags} \
        --prefix PATH : ${binPath}
    '';

in
stdenv.mkDerivation {
  pname = "omanix-scripts";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
  ''
  + lib.concatMapStringsSep "\n" installScript scripts;

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
