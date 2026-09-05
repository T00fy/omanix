{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix.quickshell;
  # Idle knobs keep their legacy top-level namespace (omanix.idle.*, defined in
  # theme/default.nix) as the user-facing surface — the shell idle service reads
  # them from shell.json (see the idle block in declaredBase below).
  idleCfg = config.omanix.idle;
  # The shell idle service has no per-stage on/off and falls back to its built-in
  # defaults (150/300s) when a key is missing, so a disabled stage is expressed as
  # a "never" timeout rather than by omission.
  idleDisabledSentinel = 86400;

  # A bar layout entry is either a bare widget id ("omanix.clock") or an object
  # carrying inline per-widget settings ({ id = "omanix.clock"; format = ...; }).
  layoutEntry = lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything);

  # Declarative base merged over the user's shell.json on every activation
  # (declared keys win). Carries the required version marker, the disabled
  # first-party plugins, the bar block driven by omanix.quickshell.bar.*, and
  # the idle block driven by omanix.idle.*.
  declaredBase = pkgs.writeText "omanix-shell.json" (builtins.toJSON {
    version = 1;
    disabledPlugins = cfg.disabledPlugins;
    bar = {
      id = "omanix.bar";
      inherit (cfg.bar) position transparent centerAnchor;
      inherit (cfg.bar) layout;
    };
    # The omanix.idle service honors only screensaver + lock timeouts (seconds);
    # dim/dpms/suspend stay on hypridle (see desktop/hypridle.nix).
    idle = {
      screensaver =
        if idleCfg.screensaver.enable then idleCfg.screensaver.timeout else idleDisabledSentinel;
      lock = if idleCfg.lock.enable then idleCfg.lock.timeout else idleDisabledSentinel;
    };
  });
in
{
  options.omanix.quickshell = {
    enable = lib.mkEnableOption "the Omanix Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.omanix-shell;
      defaultText = lib.literalExpression "pkgs.omanix-shell";
      description = "The Quickshell shell code package. OMANIX_PATH resolves to its share/omanix directory.";
    };

    disabledPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "omanix.dropbox"
        "omanix.nightlight"
        "omanix.disk-speedtest"
      ];
      description = ''
        First-party shell plugin ids seeded into shell.json's disabledPlugins,
        so the shell never invokes a command with no omanix implementer. This
        list is reconciled onto the user's config on every rebuild (declared
        config wins).
      '';
    };

    bar = {
      position = lib.mkOption {
        type = lib.types.enum [
          "top"
          "bottom"
          "left"
          "right"
        ];
        default = "top";
        description = "Screen edge the bar is anchored to.";
      };

      transparent = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the bar background is transparent.";
      };

      centerAnchor = lib.mkOption {
        type = lib.types.str;
        default = "omanix.clock";
        description = ''
          Widget id in the center section pinned to the exact screen center;
          other center entries flank it. Empty string disables anchoring.
        '';
      };

      clockFormat = lib.mkOption {
        type = lib.types.str;
        default = "dddd HH:mm";
        description = ''
          Clock widget format, using Qt date-format tokens (not strftime).
          Consumed inline by the omanix.clock entry in the default layout.
        '';
      };

      layout = lib.mkOption {
        type = lib.types.submodule {
          options = {
            left = lib.mkOption {
              type = lib.types.listOf layoutEntry;
              default = [
                { id = "omanix.menu"; }
                { id = "omanix.workspaces"; }
                { id = "omanix.active-window"; }
              ];
              description = "Widget entries in the bar's left section.";
            };
            center = lib.mkOption {
              type = lib.types.listOf layoutEntry;
              default = [
                {
                  id = "omanix.clock";
                  format = cfg.bar.clockFormat;
                }
              ];
              defaultText = lib.literalExpression ''[ { id = "omanix.clock"; format = cfg.bar.clockFormat; } ]'';
              description = "Widget entries in the bar's center section.";
            };
            right = lib.mkOption {
              type = lib.types.listOf layoutEntry;
              default = [
                {
                  id = "omanix.indicators";
                  items = [
                    "ScreenRecording"
                    "Dnd"
                    "StayAwake"
                  ];
                }
                { id = "omanix.tray"; }
                { id = "omanix.bluetooth"; }
                { id = "omanix.network"; }
                { id = "omanix.audio"; }
                { id = "omanix.power"; }
              ];
              description = "Widget entries in the bar's right section.";
            };
          };
        };
        default = { };
        description = ''
          Bar widget layout by section. Each entry is a widget id string or an
          object of { id, ...inline-settings }. Arrays are replaced wholesale on
          reconcile (declared config wins over runtime IPC edits). The default
          reproduces omanix's Waybar content set.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.quickshell
      pkgs.jq
      # gtk-launch: how the menu/launcher (AppLibrary.qml) starts desktop
      # entries. Not guaranteed on PATH by gtk.enable's theming integration.
      pkgs.gtk3
      # Runtime deps of the clipboard plugin's capture.sh, which the shell
      # spawns as wl-paste --watch: wl-paste, setpriv, pkill, plus the perl
      # UTF-16 decoder.
      pkgs.wl-clipboard
      pkgs.util-linux
      pkgs.procps
      pkgs.perl
    ];

    # Reconcile the declared base onto the user-writable shell.json. The shell
    # treats a valid user file as canonical (no in-shell merge), so this merge
    # is what re-applies declared keys each rebuild. Never a store symlink (R3)
    # — the file stays writable and is IPC-mutated at runtime.
    home.activation.omanixShellConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.config/omanix"
      _omanix_cfg="$HOME/.config/omanix/shell.json"
      if [ -f "$_omanix_cfg" ] && ${pkgs.jq}/bin/jq -e . "$_omanix_cfg" >/dev/null 2>&1; then
        run ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$_omanix_cfg" "${declaredBase}" > "$_omanix_cfg.tmp"
      else
        run cp "${declaredBase}" "$_omanix_cfg.tmp"
      fi
      run mv "$_omanix_cfg.tmp" "$_omanix_cfg"
      run chmod u+w "$_omanix_cfg"
      # Best-effort reload; a guarded no-op until the IPC CLI lands. Must never
      # fail activation whether or not the shell is running.
      run sh -c 'command -v omanix-refresh-shell >/dev/null 2>&1 && omanix-refresh-shell || true'
    '';

    # Point the shell's background overlay (omanix.background) at the declared
    # theme wallpaper. Background.qml resolves its image via
    # `readlink -f ~/.local/state/omanix/current/background` on startup. Seeded
    # as a writable symlink (not a store symlink): the declared theme is
    # reasserted each rebuild, and a runtime switcher may repoint it as an
    # ephemeral overlay.
    home.activation.omanixBackgroundState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.local/state/omanix/current"
      run ln -sfn "${config.omanix.activeTheme.assets.wallpaper}" \
        "$HOME/.local/state/omanix/current/background"
    '';
  };
}
