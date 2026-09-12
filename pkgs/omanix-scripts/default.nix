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
  pciutils,
  util-linux,
  networkmanager,
  iw,
  qrencode,
  curl,
  iproute2,
  iputils,
  bluez,
  power-profiles-daemon,
  tailscale,
  findutils,
  diffutils,
  perl,
  imagemagick,
  ffmpeg,
  zbar,
  tesseract,
  v4l-utils,
  file,
  tmux,
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
  wireplumber,
  brightnessctl,
  ddcutil,
  glib,
  usbutils,
  wl-screenrec,
  localsend,
  fzf,
  git,
  gum,
  socat,
  ttfx,
  # Data files injected by the module
  themesJson ? null,
  docStylePreview ? null,
  docStyleOverride ? null,
  docStyleGeneral ? null,
  docsDir ? null,
  themeListFormatted ? "",
  screensaverLogo ? null,
  # Which emulator the screensaver terminal spawns (omanix.terminal.bin) and the
  # zero-padding/black config it launches with (omanix.terminal.screensaverConfig).
  screensaverEmulator ? "",
  screensaverTermConfig ? null,
  # Hyprland visual defaults for gap toggling
  gapsOuter ? "10",
  gapsInner ? "5",
  borderSize ? "2",
  monitorMap ? "",
  menuWidth ? "295",
  menuMaxHeight ? "630",
  # Declared default shell font base-size (omanix.monitor.textSize), the anchor
  # for omanix-display-text-size. "12" when built standalone.
  textSizeDefault ? "12",
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
  # Declarative laptop override from omanix.hardware.isLaptop (via osConfig).
  # "true"/"false" force omanix-hw-laptop's answer; "" leaves it auto-detecting.
  isLaptop ? "",
  # Read-only speaker-tuning data (pkgs/omanix-audio-tunings). Null when the
  # scripts are built standalone; the tuning CLI then finds no tunings.
  audioTuningsDir ? null,
  # LV2 plugin dir for the tuning limiter, set only when
  # omanix.audio.speakerTuning.enable is on so lsp-plugins stays out of the
  # closure otherwise. Null leaves the tuning CLI's LV2 preflight a no-op.
  audioLv2Path ? null,
  # libretro core directory of the retroarch-with-cores package, injected only
  # when omanix.gaming.retroarch.enable is on. Null leaves the retro CLIs
  # reporting no cores.
  retroCoresDir ? null,
  # GE-Proton compatibilitytool dir, injected only when
  # omanix.gaming.battlenet.enable is on so proton-ge stays out of the closure
  # otherwise. Null leaves omanix-gaming-battlenet inert.
  protonPath ? null,
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
      # Owns settings/weather.json for the weather widget's location picker.
      name = "omanix-weather-location";
      deps = [
        bash
        coreutils
        jq
        curl
      ];
    }
    {
      # Right-click weather status string; calls the sibling location CLI.
      name = "omanix-weather-status";
      deps = [
        bash
        coreutils
        jq
        curl
      ];
      selfPath = true;
    }
    {
      # Sends desktop notifications via busctl (systemd provides it). Used by
      # the weather right-click and the reminders/notifications plugins.
      name = "omanix-notification-send";
      deps = [
        bash
        systemd
        jq
        coreutils
      ];
    }
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
      # Screensaver launcher for the omanix.idle service and the system menu.
      # Spawns one ttfx terminal (class org.omanix.screensaver) per monitor,
      # mirroring omarchy. The emulator and its zero-padding config are baked
      # from omanix.terminal.{bin,screensaverConfig}. hyprctl/jq/socat drive the
      # per-monitor spawn + openwindow wait; the emulator itself resolves off the
      # session PATH (Hyprland execs the command string).
      name = "omanix-launch-screensaver";
      deps = [
        bash
        coreutils
        hyprland
        jq
        socat
        procps
      ];
      envs = {
        OMANIX_SCREENSAVER_TERM = screensaverEmulator;
        OMANIX_SCREENSAVER_TERM_CONFIG = screensaverTermConfig;
      };
    }
    {
      # Runs inside each screensaver terminal: loops ttfx with random effects on
      # the declared logo (OMANIX_SCREENSAVER_LOGO = omanix.idle.screensaver.logo)
      # and exits on any key/mouse input or focus loss.
      name = "omanix-screensaver";
      deps = [
        bash
        coreutils
        hyprland
        jq
        procps
        ttfx
      ];
      envs = lib.optionalAttrs (screensaverLogo != null) {
        OMANIX_SCREENSAVER_LOGO = "${screensaverLogo}";
      };
    }
    {
      # Lock action for the omanix.idle service and the lock-before-sleep
      # inhibitor — drives the omanix.lock shell plugin.
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
    # ─── Coding-agent launcher (Q5-01) ───────────────────────────────
    {
      # Canonical agent map; launches the default agent in a fixed-app-id
      # window. Calls sibling omanix-launch-tui / omanix-menu.
      name = "omanix-agent";
      deps = [
        bash
        coreutils
        libnotify
      ];
      selfPath = true;
    }
    {
      # Read/set the default agent (~/.config/omanix/defaults/agent), then launch
      # via sibling omanix-agent. No install (D3).
      name = "omanix-default-agent";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
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
      # Ephemeral compositor-scale overlay for the focused monitor (Display
      # panel). Declared default is omanix.monitor.scale, re-asserted on rebuild.
      name = "omanix-hyprland-monitor-scaling";
      deps = [
        bash
        hyprland
        jq
        gawk
        coreutils
      ];
    }
    {
      # Shell font base-size + GTK text-scaling overlay (Display panel). Declared
      # default is omanix.monitor.textSize; a rebuild strips this overlay.
      name = "omanix-display-text-size";
      deps = [
        bash
        glib.bin # gsettings
        gawk
        coreutils
      ];
      envs = {
        OMANIX_TEXT_SIZE_DEFAULT = textSizeDefault;
      };
    }
    {
      # Per-monitor brightness for the Display panel: internal via brightnessctl
      # (omanix-hw-display device), external via DDC/CI (ddcutil).
      name = "omanix-brightness-display";
      deps = [
        bash
        hyprland
        jq
        gawk
        coreutils
        brightnessctl
        ddcutil
        util-linux
      ];
      selfPath = true;
    }
    {
      # 8-line state contract the Display panel polls; delegates to
      # omanix-brightness-display and omanix-hyprland-monitor-scaling.
      name = "omanix-monitor-state";
      deps = [
        bash
        hyprland
        jq
        coreutils
      ];
      selfPath = true;
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
      ];
      # Calls the sibling omanix-audio-output-set-default and omanix-osd.
      selfPath = true;
    }

    # ─── Audio subsystem (Q4-03) ─────────────────────────────────────
    {
      # Resolves a DSP/virtual sink down to the physical one loudness lives on.
      # Called unconditionally by the shell audio panel and the volume keys.
      name = "omanix-audio-output-sink";
      deps = [
        bash
        coreutils
        gawk
        pulseaudio
      ];
    }
    {
      name = "omanix-audio-sink-availability";
      deps = [
        bash
        gawk
        pulseaudio
      ];
      # Calls the sibling omanix-audio-tuning to hide a fronted physical sink.
      selfPath = true;
    }
    {
      name = "omanix-audio-output-set-default";
      deps = [
        bash
        coreutils
        gawk
        wireplumber
        pulseaudio
      ];
    }
    {
      name = "omanix-audio-input-set-default";
      deps = [
        bash
        coreutils
        gawk
        wireplumber
        pulseaudio
      ];
    }
    {
      name = "omanix-audio-output-volume";
      deps = [
        bash
        coreutils
        gawk
        pulseaudio
      ];
      # Calls the sibling omanix-audio-output-sink and omanix-osd.
      selfPath = true;
    }
    {
      name = "omanix-audio-source-switch";
      deps = [ bash ];
      # Drives the shell's Mpris media service over IPC (omanix-shell).
      selfPath = true;
    }
    {
      name = "omanix-brightness";
      deps = [
        bash
        coreutils
        gawk
        brightnessctl
      ];
      # Calls the sibling omanix-osd.
      selfPath = true;
    }
    {
      name = "omanix-audio-tuning";
      deps = [
        bash
        coreutils
        gawk
        gnugrep
        gnused
        procps
        systemd
        pulseaudio
      ];
      # Calls the sibling omanix-audio-output-sink; the systemd unit it drives is
      # declared by Nix (omanix.audio.speakerTuning.enable).
      selfPath = true;
      envs = {
        OMANIX_AUDIO_TUNINGS = audioTuningsDir;
        OMANIX_AUDIO_LV2_PATH = audioLv2Path;
      };
    }
    {
      name = "omanix-restart-audio";
      deps = [
        bash
        coreutils
        gawk
        gnused
        systemd
        wireplumber
        usbutils
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
      # Palette-only theme targets: pushed by omanix-theme-set's
      # best-effort tail and reasserted declaratively (tmux via apps/tmux.nix,
      # claude via apps/ai.nix). Each reads current/theme/ and no-ops when its
      # target isn't present.
      #
      # Emit OSC retint sequences from a colors.toml (calls omanix-theme-color).
      name = "omanix-theme-osc";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }
    {
      # Live-retint a running tmux server (colors/cursor/COLORFGBG/OSC).
      name = "omanix-theme-set-tmux";
      deps = [
        bash
        tmux
        coreutils
        gawk
        procps
      ];
      selfPath = true;
    }
    {
      # Copy current/theme/claude.json -> ~/.claude/themes/omanix.json; --activate
      # sets settings.theme = custom:omanix.
      name = "omanix-theme-set-claude";
      deps = [
        bash
        coreutils
        jq
      ];
    }
    {
      # Copy current/theme/pi.json -> ~/.pi/agent/themes/omanix-system.json.
      name = "omanix-theme-set-pi";
      deps = [
        bash
        coreutils
        jq
      ];
    }
    {
      # Ephemeral retint of a running herdr. The declared theme is name =
      # "terminal" (apps/herdr.nix), so reloading the server picks up the
      # current terminal palette. herdr resolves off the session PATH.
      name = "omanix-theme-set-herdr";
      deps = [
        bash
        coreutils
        jq
      ];
    }
    # ─── herdr multiplexer (Q4-11) ───────────────────────────────────
    {
      # Reload a running herdr server's config. herdr resolves off the session
      # PATH (home.packages when omanix.apps.herdr.enable), so it stays out of
      # the scripts closure and no-ops when herdr is absent.
      name = "omanix-restart-herdr";
      deps = [
        bash
        coreutils
        jq
      ];
    }
    {
      # Annotated herdr keybindings viewer: parses `herdr --default-config` +
      # the user config, then picks via the sibling omanix-menu-dmenu.
      name = "omanix-menu-herdr-keybindings";
      deps = [
        bash
        gawk
        coreutils
      ];
      selfPath = true;
    }
    {
      name = "omanix-toggle-idle";
      deps = [
        bash
        coreutils
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

    # ─── Capture tools (Q4-05) ───────────────────────────────────────
    {
      # Decode a QR from a slurp-selected region; result to wl-copy --sensitive
      # only (never printed/logged — QRs carry secrets).
      name = "omanix-capture-qr";
      deps = [
        bash
        coreutils
        hyprpicker
        slurp
        grim
        zbar
        wl-clipboard
        libnotify
      ];
    }
    {
      # OCR a slurp-selected region to the clipboard. Language via OMANIX_OCR_LANGS.
      name = "omanix-capture-text";
      deps = [
        bash
        coreutils
        hyprpicker
        slurp
        grim
        tesseract
        wl-clipboard
        libnotify
      ];
    }
    {
      # Shared region picker over a frozen screen; also drives keyboard window
      # selection while slurp is open (invoked by the layer binds in bindings.nix).
      name = "omanix-capture-region";
      deps = [
        bash
        coreutils
        hyprland
        jq
        slurp
        hyprpicker
        procps
      ];
    }
    {
      # List V4L2 devices that truly support Video Capture. Consumed by
      # omanix-hw-webcam (Q4-02).
      name = "omanix-capture-webcam-list";
      deps = [
        bash
        coreutils
        gawk
        v4l-utils
      ];
    }
    {
      # Transcode an image/video to a size-optimized file on the clipboard.
      # Interactive pickers go through the sibling omanix-menu-dmenu.
      name = "omanix-transcode";
      deps = [
        bash
        coreutils
        file
        imagemagick
        ffmpeg
        wl-clipboard
        libnotify
        findutils
      ];
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
    # ── Plugin system ──────────────────────────────────────────────────
    # Plugins are installed declaratively (omanix.quickshell.plugins); there is
    # no runtime fetch/clone. These CLIs only inspect installed plugins and
    # flip runtime enable/disable state as an ephemeral overlay.
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
      # Menu wrapper: lists via omanix-plugin-list, picks via omanix-menu-dmenu,
      # dispatches enable/disable over IPC.
      name = "omanix-menu-plugin";
      deps = [
        bash
        coreutils
        jq
        libnotify
      ];
      selfPath = true;
    }

    # ─── Hardware detection (Q4-02) ──────────────────────────────────
    {
      # omanix.hardware.isLaptop overrides the probe via OMANIX_IS_LAPTOP.
      name = "omanix-hw-laptop";
      deps = [
        bash
        coreutils
        gnugrep
      ];
      envs = {
        OMANIX_IS_LAPTOP = if isLaptop == "" then null else isLaptop;
      };
    }
    {
      name = "omanix-hw-laptop-closed";
      deps = [
        bash
        coreutils
        gnugrep
      ];
    }
    {
      name = "omanix-hw-clamshell";
      deps = [
        bash
        coreutils
        gnugrep
      ];
      selfPath = true;
    }
    {
      name = "omanix-hw-display";
      deps = [
        bash
        coreutils
        gnugrep
      ];
    }
    {
      name = "omanix-hw-fingerprint";
      deps = [
        bash
        coreutils
        gnugrep
      ];
    }
    {
      name = "omanix-hw-nvidia";
      deps = [
        bash
        coreutils
        gnugrep
      ];
    }
    {
      name = "omanix-hw-intel-sof";
      deps = [
        bash
        coreutils
        gnugrep
        pciutils
      ];
    }
    {
      # Delegates to omanix-capture-webcam-list (Q4-05) when present.
      name = "omanix-hw-webcam";
      deps = [
        bash
        coreutils
      ];
      selfPath = true;
    }

    # ─── Power-panel data emitters (Q4-02) ───────────────────────────
    {
      name = "omanix-battery-status";
      deps = [
        bash
        coreutils
        gawk
      ];
    }
    {
      name = "omanix-system-stats";
      deps = [
        bash
        coreutils
        gawk
        procps
      ];
    }

    # ─── Network / DNS / Bluetooth / Power panels (Q4-04) ────────────
    {
      # Dual mode: bare line for the speedtest panel, key/value pairs under
      # --verbose for the network panel. NetworkManager is host-provided.
      name = "omanix-network-status";
      deps = [
        bash
        coreutils
        gawk
        networkmanager
        iproute2
        iputils
      ];
    }
    {
      # Query the active Wi-Fi band, or pin one and reactivate (reverts on
      # failure). Available bands come from a cached iw scan.
      name = "omanix-network-band";
      deps = [
        bash
        coreutils
        gawk
        networkmanager
        iw
      ];
    }
    {
      # Emit the active network's WIFI: QR payload as a square 0/1 matrix.
      name = "omanix-network-qr";
      deps = [
        bash
        coreutils
        gawk
        networkmanager
        qrencode
      ];
    }
    {
      name = "omanix-network-password";
      deps = [
        bash
        coreutils
        networkmanager
      ];
    }
    {
      # Stream Mbps samples for the speedtest panel's down/up phases.
      name = "omanix-network-speedtest";
      deps = [
        bash
        coreutils
        gawk
        curl
        iproute2
      ];
    }
    {
      # Read or pin the DNS provider on the active connection.
      name = "omanix-dns";
      deps = [
        bash
        coreutils
        gawk
        networkmanager
      ];
    }
    {
      name = "omanix-bluetooth-device";
      deps = [
        bash
        coreutils
        bluez
      ];
    }
    {
      # Moves the rfkill soft block so the state persists across reboots.
      name = "omanix-bluetooth-power";
      deps = [
        bash
        coreutils
        util-linux
        bluez
      ];
    }
    {
      # power-profiles-daemon is the NixOS default; the helper degrades to a
      # no-op (exit 0) when it is absent so a TLP host is left alone.
      name = "omanix-powerprofiles-list";
      deps = [
        bash
        coreutils
        gawk
        gnugrep
        power-profiles-daemon
      ];
    }
    {
      name = "omanix-powerprofiles-set";
      deps = [
        bash
        coreutils
        gawk
        gnugrep
        power-profiles-daemon
      ];
    }
    {
      # Floating-terminal file picker for headless callers (the shell tailscale
      # panel invokes omanix-tailscale-send without a controlling terminal).
      name = "omanix-file-select";
      deps = [
        bash
        coreutils
        findutils
        fzf
        terminalWrapper
      ];
    }
    {
      # Taildrop send; with no file arg falls back to omanix-file-select.
      name = "omanix-tailscale-send";
      deps = [
        bash
        coreutils
        tailscale
        libnotify
      ];
      selfPath = true;
    }
    {
      # Long-running Taildrop receiver (systemd user service, see
      # modules/home-manager/desktop/tailscale.nix); also runs by hand.
      name = "omanix-tailscale-receive";
      deps = [
        bash
        coreutils
        file
        tailscale
        libnotify
        xdg-utils
      ];
    }

    # ─── Gaming (Q4-08) ──────────────────────────────────────────────
    {
      # List installed libretro cores from the nix-provided core dir with
      # friendly system labels.
      name = "omanix-games-retro-cores";
      deps = [
        bash
        coreutils
      ];
      envs = {
        OMANIX_RETRO_CORES_DIR = retroCoresDir;
      };
    }
    {
      # Create a per-ROM .desktop launcher; picks core+ROM interactively via the
      # sibling omanix-games-retro-cores / omanix-menu-dmenu / omanix-file-select.
      name = "omanix-games-retro-install";
      deps = [
        bash
        coreutils
        gnused
      ];
      selfPath = true;
      envs = {
        OMANIX_RETRO_CORES_DIR = retroCoresDir;
      };
    }
    {
      # Install/launch Battle.net through umu + GE-Proton. umu-run comes from the
      # session PATH (added by the gaming module when enabled); the GE-Proton dir
      # arrives via OMANIX_PROTON_PATH.
      name = "omanix-gaming-battlenet";
      deps = [
        bash
        coreutils
        curl
      ];
      envs = {
        OMANIX_PROTON_PATH = protonPath;
      };
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
