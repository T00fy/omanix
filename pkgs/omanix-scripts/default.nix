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
  procps,
  systemd,
  walker,
  gawk,
  gnused,
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
  hyprlock,
  bitwarden-cli,
  pulseaudio,
  swayosd,
  gpu-screen-recorder,
  ffmpeg,
  v4l-utils,
  hypridle,
  localsend,
  fzf,
  # Configurable options
  browserFallback ? "firefox.desktop",
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
}:

let
  # Helper: generate --set flags from an attrset, skipping null values
  mkEnvFlags = envs:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (k: v:
        if v != null then ''--set ${k} "${v}"'' else ""
      ) envs
    );

  # ═══════════════════════════════════════════════════════════════════
  # Script Definitions
  # Each entry defines: name, runtime deps, env vars, and whether
  # it needs $out/bin on PATH (for calling sibling scripts).
  # ═══════════════════════════════════════════════════════════════════
  scripts = [
    {
      name = "omanix-launch-browser";
      deps = [ bash xdg-utils ];
      envs = { OMANIX_BROWSER_FALLBACK = browserFallback; };
    }
    {
      name = "omanix-launch-or-focus";
      deps = [ bash hyprland jq coreutils ];
    }
    {
      name = "omanix-launch-tui";
      deps = [ bash ghostty coreutils ];
    }
    {
      name = "omanix-launch-or-focus-tui";
      deps = [ bash coreutils ];
      selfPath = true;
    }
    {
      name = "omanix-cmd-terminal-cwd";
      deps = [ bash hyprland jq procps coreutils ];
    }
    {
      name = "omanix-launch-walker";
      deps = [ bash procps systemd coreutils ];
      envs = { WALKER_BIN = "${walker}/bin/walker"; };
    }
    {
      name = "omanix-smart-delete";
      deps = [ bash hyprland jq ];
    }
    {
      name = "omanix-menu";
      deps = [ bash coreutils hyprpicker libnotify systemd xdg-utils ];
      envs = {
        WALKER_BIN = "${walker}/bin/walker";
        OMANIX_SCREENSAVER_LOGO = screensaverLogo;
      };
      selfPath = true;
    }
    {
      name = "omanix-menu-style";
      deps = [ bash jq coreutils gnused envsubst swaybg ghostty glow ];
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
      deps = [ bash gawk libxkbcommon hyprland jq gnused coreutils ];
      selfPath = true;
    }
    {
      name = "omanix-show-style-help";
      deps = [ bash coreutils gnused ghostty glow ];
      envs = {
        OMANIX_DOC_STYLE = docStyleGeneral;
        OMANIX_THEME_LIST = themeListFormatted;
      };
    }
    {
      name = "omanix-show-setup-help";
      deps = [ bash ghostty glow coreutils ];
      envs = {
        OMANIX_DOCS_DIR = docsDir;
      };
    }
    {
      name = "omanix-cmd-logout";
      deps = [ bash hyprland jq coreutils ];
    }
    {
      name = "omanix-restart-walker";
      deps = [ bash systemd libnotify coreutils ];
    }
    {
      name = "omanix-launch-audio";
      deps = [ bash pavucontrol ];
    }
    {
      name = "omanix-launch-wifi";
      deps = [ bash ];
      selfPath = true;
    }
    {
      name = "omanix-launch-bluetooth";
      deps = [ bash ];
      selfPath = true;
    }
    {
      name = "omanix-toggle-waybar";
      deps = [ bash systemd ];
    }
    {
      name = "omanix-cmd-screenshot";
      deps = [ bash coreutils jq gawk procps hyprland grim slurp wl-clipboard wayfreeze libnotify ];
    }
    {
      name = "omanix-lock-screen";
      deps = [ bash hyprland hyprlock libnotify bitwarden-cli procps ];
    }
    {
      name = "omanix-cmd-shutdown";
      deps = [ bash hyprland jq coreutils systemd ];
    }
    {
      name = "omanix-cmd-reboot";
      deps = [ bash hyprland jq coreutils systemd ];
    }
    {
      name = "omanix-cmd-audio-switch";
      deps = [ bash jq hyprland pulseaudio swayosd ];
    }
    {
      name = "omanix-hyprland-window-close-all";
      deps = [ bash hyprland jq coreutils ];
    }
    {
      name = "omanix-hyprland-window-pop";
      deps = [ bash hyprland jq ];
    }
    {
      name = "omanix-hyprland-workspace-toggle-gaps";
      deps = [ bash hyprland jq ];
      envs = {
        OMANIX_GAPS_OUTER = gapsOuter;
        OMANIX_GAPS_INNER = gapsInner;
        OMANIX_BORDER_SIZE = borderSize;
      };
    }
    {
      name = "omanix-theme-bg-next";
      deps = [ bash coreutils swaybg libnotify procps ];
      envs = { OMANIX_WALLPAPERS = wallpaperList; };
    }
    {
      name = "omanix-toggle-idle";
      deps = [ bash procps hypridle libnotify ];
    }
    {
      name = "omanix-cmd-screenrecord";
      deps = [ bash coreutils jq gawk procps hyprland gpu-screen-recorder ffmpeg v4l-utils libnotify waybar wl-clipboard ];
    }
    {
      name = "omanix-workspace";
      deps = [ bash hyprland jq ];
      envs = { OMANIX_MONITOR_MAP = monitorMap; };
    }
    {
      name = "omanix-cmd-share";
      deps = [ bash coreutils wl-clipboard libnotify systemd fzf localsend ];
    }
  ];

  # ═══════════════════════════════════════════════════════════════════
  # Generate install commands for a single script
  # ═══════════════════════════════════════════════════════════════════
  installScript = { name, deps, envs ? {}, selfPath ? false, ... }:
    let
      binPath =
        (lib.optionalString selfPath "$out/bin:") +
        lib.makeBinPath deps;

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
  '' + lib.concatMapStringsSep "\n" installScript scripts;

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
