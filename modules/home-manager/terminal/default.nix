{ config, lib, pkgs, ... }:
let
  cfg = config.omanix.terminal;

  emulators = {
    ghostty = { pkg = pkgs.ghostty; classFlag = "--class"; execFlag = "-e"; };
    foot = { pkg = pkgs.foot; classFlag = "--app-id"; execFlag = null; };
  };

  emu = emulators.${cfg.emulator};

  execLine = if emu.execFlag != null
    then ''exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}" ${emu.execFlag} "''${CMD[@]}"''
    else ''exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}" "''${CMD[@]}"'';

  # foot has no signal/IPC to live-resize the font of an already-open
  # window (only SIGUSR1/2, for the color theme) — see
  # modules/home-manager/terminal/foot.nix. So the scaled font only applies
  # to NEW windows, via a CLI override on launch, gated on the same state
  # files omanix-scale (runtime Moonlight UI-scale toggle) uses for its two
  # independent toggles — scaledDesktop and dummyDisplay. Checked as a
  # chained if/elif, not two independent ifs, since only one can plausibly
  # be active at once and this avoids ever appending -o main.font twice
  # (foot uses the last one, but no reason to rely on that). Revisit if foot
  # ever gains a live font-resize API.
  scaledFootArgs = lib.optionalString (cfg.emulator == "foot") ''
    if [[ -f "''${XDG_RUNTIME_DIR:-/tmp}/omanix-scale-active" ]]; then
      ARGS+=(-o "main.font=${config.omanix.font}:size=${toString cfg.scaledFontSize}")
    elif [[ -f "''${XDG_RUNTIME_DIR:-/tmp}/omanix-dummy-display-active" ]]; then
      ARGS+=(-o "main.font=${config.omanix.font}:size=${toString cfg.dummyDisplayFontSize}")
    fi
  '';

  # Config the screensaver terminal launches with: zero padding and a black
  # background so ttfx paints edge-to-edge. ghostty merges this over the user
  # config (`--config-file=`); foot's `--config=` replaces it outright, so the
  # foot variant must be self-contained (font + colors).
  screensaverConfig =
    if cfg.emulator == "ghostty" then
      pkgs.writeText "ghostty-screensaver" ''
        window-padding-x = 0
        window-padding-y = 0
        window-padding-color = "extend-always"
      ''
    else
      pkgs.writeText "foot-screensaver.ini" ''
        [main]
        font=${config.omanix.font}:size=18
        pad=0x0

        [colors-dark]
        background=000000
        foreground=ffffff
      '';

  terminalWrapper = pkgs.writeShellScriptBin "omanix-term" ''
    CLASS=""
    CWD=""
    CMD=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --class=*) CLASS="''${1#--class=}"; shift ;;
        --cwd=*) CWD="''${1#--cwd=}"; shift ;;
        --) shift; CMD=("$@"); break ;;
        *) CMD=("$@"); break ;;
      esac
    done
    ARGS=()
    [[ -n "$CLASS" ]] && ARGS+=(${emu.classFlag}="$CLASS")
    [[ -n "$CWD" ]] && ARGS+=(--working-directory="$CWD")
    ${scaledFootArgs}
    if [[ ''${#CMD[@]} -gt 0 ]]; then
      ${execLine}
    else
      exec ${emu.pkg}/bin/${cfg.emulator} "''${ARGS[@]}"
    fi
  '';
in
{
  imports = [
    ./ghostty.nix
    ./foot.nix
  ];

  options.omanix.terminal = {
    emulator = lib.mkOption {
      type = lib.types.enum [ "ghostty" "foot" ];
      default = "ghostty";
      description = "Which terminal emulator to use.";
    };

    mouseScrollMultiplier = lib.mkOption {
      type = lib.types.float;
      default = 5.0;
      description = "Mouse scroll multiplier. Higher values scroll more lines per tick.";
    };

    bin = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = cfg.emulator;
      description = "Terminal binary name.";
    };

    wrapper = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = terminalWrapper;
      description = "The omanix-term wrapper package.";
    };

    screensaverConfig = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      default = screensaverConfig;
      description = "Emulator config file the screensaver terminal launches with (zero padding, black background).";
    };
  };

  config = {
    home.packages = [
      terminalWrapper
    ];
  };
}
