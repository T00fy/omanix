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
  gawk,
  gnugrep,
  gnused,
  util-linux,
  findutils,
  diffutils,
  perl,
  imagemagick,
  quickshell,
  libxkbcommon,
  libnotify,
  vips,
  glow,
  pavucontrol,
  hyprpicker,
  wayfreeze,
  grim,
  slurp,
  wl-clipboard,
  wtype,
  pulseaudio,
  swayosd,
  wl-screenrec,
  hypridle,
  localsend,
  fzf,
  git,
  gum,
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
  monitorMap ? "",
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
  # Store path of the Nix-generated declarative shell.json base (quickshell.nix).
  # Null when the desktop shell module is disabled.
  shellDefaults ? null,
  # Store path of all themes' rendered colors.toml + shell.toml, per-slug
  # (quickshell.nix themesDir). omanix-theme-set resolves runtime switches
  # against it. Null when the desktop shell module is disabled.
  quickshellThemesDir ? null,
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
      # Sourced helper library for the shell-management CLIs; run directly it
      # prints the current resolved shell config. DEFAULTS_FILE = the declared
      # base rendered by quickshell.nix.
      name = "omanix-shell-config";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
      envs = {
        OMANIX_SHELL_DEFAULTS = shellDefaults;
      };
    }
    {
      name = "omanix-bar";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
      envs = {
        OMANIX_SHELL_DEFAULTS = shellDefaults;
      };
    }
    {
      # Invoked by the bar QML to pick a legible transparent-bar text color.
      name = "omanix-bar-text-color";
      deps = [
        bash
        coreutils
        gawk
        jq
        imagemagick
        hyprland
      ];
    }
    {
      name = "omanix-hyprland-session-locked";
      deps = [
        bash
        hyprland
        jq
      ];
    }
    {
      name = "omanix-restart-shell";
      deps = [
        bash
        coreutils
        findutils
        gnused
        jq
        systemd
        hyprland
        quickshell
      ];
      selfPath = true;
    }
    {
      # Manual trigger of the activation-time shell.json reconcile.
      name = "omanix-refresh-shell";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
      envs = {
        OMANIX_SHELL_DEFAULTS = shellDefaults;
      };
    }
    {
      name = "omanix-toggle-bar";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
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
      name = "omanix-menu-dmenu";
      deps = [
        bash
        jq
        coreutils
      ];
      # Calls the sibling omanix-shell to summon omanix.menu in dmenu mode.
      selfPath = true;
    }
    {
      name = "omanix-menu-style";
      deps = [
        bash
        jq
        coreutils
      ];
      envs = {
        OMANIX_THEMES_FILE = themesJson;
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
      # Cycle the active theme's declared wallpapers via the current/background
      # symlink (delegates to omanix-theme-bg-set; no swaybg / separate state).
      name = "omanix-theme-bg-next";
      deps = [
        bash
        coreutils
        findutils
      ];
      selfPath = true;
    }
    {
      # Shared image-picker CLI: drives the omanix.image-picker plugin over the
      # image-selector IPC (thumbnail cache via vips). Used by the bg helpers.
      name = "omanix-menu-images";
      deps = [
        bash
        coreutils
        findutils
        gawk
        util-linux
        diffutils
        vips
      ];
      selfPath = true;
    }
    {
      # Set the current background: repoint current/background + live IPC push.
      name = "omanix-theme-bg-set";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }
    {
      # Open the wallpaper picker for the active theme's backgrounds.
      name = "omanix-theme-bg-switcher";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }
    {
      # Pretty-print the current background's name.
      name = "omanix-theme-bg-current";
      deps = [
        bash
        coreutils
        perl
      ];
    }
    {
      # Pre-warm the picker's thumbnail cache for the active theme.
      name = "omanix-theme-bg-cache";
      deps = [ bash ];
      selfPath = true;
    }
    {
      # Shared colors.toml palette resolver (alias/fallback cascade + mode
      # detection). Consumed by palette-only theme targets.
      name = "omanix-theme-color";
      deps = [
        bash
        coreutils
        gawk
      ];
    }
    {
      # Ephemeral runtime theme switch: repoints current/theme at a built slug
      # and re-themes a running shell via applyTheme IPC.
      name = "omanix-theme-set";
      deps = [
        bash
        coreutils
        gnused
        util-linux
      ];
      selfPath = true;
      envs = {
        OMANIX_THEMES_DIR = quickshellThemesDir;
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
      # Calls the sibling omanix-shell to refresh the recording indicator.
      selfPath = true;
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
    # ── Plugin system (Q4-01) ──────────────────────────────────────────
    {
      # Shared guard: refuse transport-helper / option-injection git URLs
      # before any clone. Also reused by theme install.
      name = "omanix-git-url-check";
      deps = [ bash ];
    }
    {
      # Mirrors PluginRegistry.qml's manifest schema so the CLI rejects
      # anything the shell would refuse or load unsafely.
      name = "omanix-plugin-validate";
      deps = [
        bash
        coreutils
        jq
        findutils
      ];
    }
    {
      # Single source of truth for manifest walking (first-party + user).
      # Reads $OMANIX_PATH from the session env; no running shell needed.
      name = "omanix-plugin-catalog";
      deps = [
        bash
        coreutils
        jq
        findutils
      ];
    }
    {
      name = "omanix-plugin-list";
      deps = [
        bash
        coreutils
        jq
        gawk
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-enable";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-disable";
      deps = [
        bash
        coreutils
        jq
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-add";
      deps = [
        bash
        coreutils
        jq
        git
        gum
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-clone";
      deps = [
        bash
        coreutils
        jq
        gnused
        gnugrep
        libnotify
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-update";
      deps = [
        bash
        coreutils
        jq
        git
        gum
      ];
      selfPath = true;
    }
    {
      name = "omanix-plugin-remove";
      deps = [
        bash
        coreutils
        jq
        gum
        findutils
        libnotify
      ];
      selfPath = true;
    }
    {
      # Menu wrapper: lists via omanix-plugin-list, picks via omanix-menu-dmenu,
      # dispatches enable/disable over IPC and clone/remove in a floating term.
      name = "omanix-menu-plugin";
      deps = [
        bash
        coreutils
        jq
        libnotify
      ];
      selfPath = true;
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
