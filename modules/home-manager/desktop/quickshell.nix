{
  config,
  lib,
  pkgs,
  omanixLib,
  ...
}:
let
  cfg = config.omanix.quickshell;

  # All themes' rendered colors.toml + shell.toml (Q2-01/Q2-02), materialized
  # into the store as <slug>/{colors.toml,shell.toml}. This is the declarative
  # baseline: the declared omanix.theme is seeded from here on activation, and
  # omanix-theme-set (Q2-04) resolves runtime switches against the same tree.
  # Both attrsets are keyed by theme slug (see lib/themes.nix, lib/default.nix).
  #
  # Each slug also gets a backgrounds/ subdir symlinking that theme's declared
  # assets.wallpapers. Since current/theme -> ${themesStore}/<slug>, the picker
  # resolves current/theme/backgrounds for whichever theme is active (Q2-05).
  #
  # Each slug also carries the palette-only agent theme sources claude.json +
  # pi.json; omanix-theme-set-{claude,pi} copy current/theme/{claude,pi}.json.
  themesStore = pkgs.linkFarm "omanix-themes" (
    lib.concatLists (
      lib.mapAttrsToList (
        slug: colorsToml:
        [
          {
            name = "${slug}/colors.toml";
            path = pkgs.writeText "${slug}-colors.toml" colorsToml;
          }
          {
            name = "${slug}/shell.toml";
            path = pkgs.writeText "${slug}-shell.toml" omanixLib.themesShellToml.${slug};
          }
          {
            name = "${slug}/claude.json";
            path = pkgs.writeText "${slug}-claude.json" omanixLib.themesClaudeJson.${slug};
          }
          {
            name = "${slug}/pi.json";
            path = pkgs.writeText "${slug}-pi.json" omanixLib.themesPiJson.${slug};
          }
        ]
        ++ map (wp: {
          name = "${slug}/backgrounds/${builtins.baseNameOf wp}";
          path = wp;
        }) omanixLib.themes.${slug}.assets.wallpapers
      ) omanixLib.themesColorsToml
    )
  );
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

  # The AI agent usage widget (omanix.agents) is opt-in via omanix.apps.ai
  # (apps/ai.nix). When enabled it is placed in the bar with its per-provider
  # enablement and refresh interval carried as inline settings; a disabled
  # provider is skipped by the widget and its collector run. Empty list when off,
  # so the plugin never activates and nothing polls for usage.
  aiUsage = config.omanix.apps.ai.usageWidget;
  agentsBarEntry = lib.optional aiUsage.enable {
    id = "omanix.agents";
    inherit (aiUsage) refreshIntervalSec;
    providers = {
      claude = { enabled = aiUsage.providers.claude; };
      codex = { enabled = aiUsage.providers.codex; };
      fireworks = { enabled = aiUsage.providers.fireworks; };
    };
  };

  # Third-party plugins declared via omanix.quickshell.plugins whose enable is
  # true, recorded as plugins[] entries (panels/services/overlays/menus). Bar
  # widgets are placed via omanix.quickshell.bar.layout instead, so those are
  # declared with enable = false (installed but not auto-added to plugins[]).
  enabledPluginIds = lib.attrNames (lib.filterAttrs (_: p: p.enable) cfg.plugins);

  # Declarative base merged over the user's shell.json on every activation
  # (declared keys win). Carries the required version marker, the disabled
  # first-party plugins, the enabled third-party plugins, the bar block driven
  # by omanix.quickshell.bar.*, and the idle block driven by omanix.idle.*.
  declaredBase = pkgs.writeText "omanix-shell.json" (builtins.toJSON {
    version = 1;
    disabledPlugins = cfg.disabledPlugins;
    plugins = map (id: { inherit id; }) enabledPluginIds;
    bar = {
      id = "omanix.bar";
      inherit (cfg.bar) position transparent centerAnchor;
      inherit (cfg.bar) layout;
    };
    # The omanix.idle service is the single idle owner: screensaver + lock
    # timeouts (seconds). There is no idle-dim / idle-DPMS-off / auto-suspend —
    # the fullscreen screensaver is the blanking, and lock-before-suspend is a
    # declarative delay-inhibitor service (desktop/lock-before-sleep.nix).
    idle = {
      screensaver =
        if idleCfg.screensaver.enable then idleCfg.screensaver.timeout else idleDisabledSentinel;
      lock = if idleCfg.lock.enable then idleCfg.lock.timeout else idleDisabledSentinel;
    };
  });
in
{
  options.omanix.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable the Omanix Quickshell desktop shell — the single
        process that hosts the bar, launcher/menu, notifications, OSD, lock,
        polkit agent, clipboard and background. This is the only supported
        desktop; the discrete-tool stack (waybar/walker/mako/hyprlock/…) it
        replaced has been removed.
      '';
    };

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

    plugins = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (_: {
          options = {
            source = lib.mkOption {
              type = lib.types.path;
              description = ''
                Directory containing the plugin's manifest.json (and its QML).
                Pin it: a fetchFromGitHub with a fixed rev + hash, a flake
                input, or a local path. It is built into the store and
                symlinked read-only into ~/.config/omanix/plugins/<name>, which
                the shell's PluginRegistry scans on startup.
              '';
            };
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Record this plugin as enabled in shell.json's plugins[] on
                every rebuild (for panels, services, overlays, and menus). Set
                to false for bar-widget or bar plugins — those are still
                installed, but you enable them by placing their id in
                omanix.quickshell.bar.layout (or as the bar id) instead.
              '';
            };
          };
        })
      );
      default = { };
      example = lib.literalExpression ''
        {
          "acme.weather" = {
            source = pkgs.fetchFromGitHub {
              owner = "acme";
              repo = "omanix-weather";
              rev = "v1.2.0";
              hash = "sha256-AAAA...";
            };
          };
        }
      '';
      description = ''
        Declaratively installed third-party shell plugins, keyed by plugin id
        (the attribute name must match the manifest id). Each source is pinned
        and built into the store — nothing is fetched or cloned at runtime.
        Installing, updating, or removing a plugin means editing this option
        and rebuilding. Runtime enable/disable (omanix-plugin-{enable,disable})
        remains available as an ephemeral overlay that a rebuild reasserts.
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
                { id = "omanix.media"; }
                {
                  id = "omanix.clock";
                  format = cfg.bar.clockFormat;
                }
              ];
              defaultText = lib.literalExpression ''[ { id = "omanix.media"; } { id = "omanix.clock"; format = cfg.bar.clockFormat; } ]'';
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
                # The network panel drives its list/connect actions through
                # NetworkManager (Quickshell.Networking + nmcli); the host must
                # enable networking.networkmanager for it to be functional.
                { id = "omanix.network"; }
                { id = "omanix.audio"; }
                { id = "omanix.power"; }
              ]
              ++ agentsBarEntry;
              defaultText = lib.literalExpression ''[ { id = "omanix.indicators"; ... } { id = "omanix.tray"; } { id = "omanix.bluetooth"; } { id = "omanix.network"; } { id = "omanix.audio"; } { id = "omanix.power"; } ] ++ (optional omanix.apps.ai.usageWidget.enable { id = "omanix.agents"; ... })'';
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

    # Internal: the store path of the declarative shell.json base, exposed so
    # the shell-management CLIs (omanix-refresh-shell, omanix-bar) reconcile
    # against the exact same base as activation.
    declaredBaseFile = lib.mkOption {
      type = lib.types.path;
      internal = true;
      readOnly = true;
      default = declaredBase;
      description = "Store path of the Nix-generated declarative shell.json base.";
    };

    # Internal: the store path of all themes' rendered tomls, exposed so
    # omanix-theme-set (Q2-04) resolves runtime switches against the same tree
    # the declarative baseline is seeded from.
    themesDir = lib.mkOption {
      type = lib.types.path;
      internal = true;
      readOnly = true;
      default = themesStore;
      description = "Store path of all themes' rendered colors.toml + shell.toml (per-slug).";
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

    # Install declared third-party plugins as read-only store symlinks into the
    # dir the shell's PluginRegistry scans. Nothing is fetched at runtime; the
    # source is pinned and built into the store by omanix.quickshell.plugins.
    xdg.configFile = lib.mapAttrs' (
      id: p: lib.nameValuePair "omanix/plugins/${id}" { inherit (p) source; }
    ) cfg.plugins;

    # Reconcile the declared base onto the user-writable shell.json. The shell
    # treats a valid user file as canonical (no in-shell merge), so this merge
    # is what re-applies declared keys each rebuild. Never a store symlink (R3)
    # — the file stays writable and is IPC-mutated at runtime.
    home.activation.omanixShellConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.config/omanix"
      _omanix_cfg="$HOME/.config/omanix/shell.json"
      if [ -f "$_omanix_cfg" ] && ${pkgs.jq}/bin/jq -e . "$_omanix_cfg" >/dev/null 2>&1; then
        # Shallow, right-biased merge: every key the declared base defines is
        # taken wholesale from the base (so a removed or renamed declared
        # sub-key does not linger under bar/idle), while any runtime-only
        # top-level key the base doesn't define is preserved.
        run ${pkgs.jq}/bin/jq -s '.[0] + .[1]' "$_omanix_cfg" "${declaredBase}" > "$_omanix_cfg.tmp"
      else
        # Present but not valid JSON: keep it as .corrupt instead of silently
        # discarding accumulated runtime state, then start from the base.
        [ -e "$_omanix_cfg" ] && run mv "$_omanix_cfg" "$_omanix_cfg.corrupt"
        run cp "${declaredBase}" "$_omanix_cfg.tmp"
      fi
      run mv "$_omanix_cfg.tmp" "$_omanix_cfg"
      run chmod u+w "$_omanix_cfg"
      # Best-effort live reload only — the merge above is authoritative, so we
      # do NOT re-merge via omanix-refresh-shell here. Must never fail
      # activation whether or not the shell is running.
      run sh -c '
        if command -v omanix-shell >/dev/null 2>&1; then
          omanix-shell shell reloadConfig >/dev/null 2>&1 \
            || omanix-shell -q shell rescanPlugins >/dev/null 2>&1 || true
        fi'
    '';

    # Point the shell's background overlay (omanix.background) at the declared
    # theme wallpaper. Background.qml resolves its image via
    # `readlink -f ~/.local/state/omanix/current/background` on startup. Seeded
    # as a writable symlink (not a store symlink): the declared theme is
    # reasserted each rebuild, and a runtime switcher may repoint it as an
    # ephemeral overlay.
    home.activation.omanixBackgroundState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${omanixLib.state.rootExpr}/current"
      run ln -sfn "${config.omanix.activeTheme.assets.wallpaper}" \
        "${omanixLib.state.rootExpr}/current/background"
    '';

    # Apply the declared theme (D2 source of truth). The shell reads
    # current/theme/{colors.toml,shell.toml} on cold start (Color.qml FileViews,
    # unwatched), so the seeded symlink themes a not-yet-running shell; the IPC
    # push re-themes an already-running one (its FileViews don't watch). Seeded
    # as a writable symlink into the store (not a store symlink) so a rebuild
    # reasserts the declared theme while omanix-theme-set (Q2-04) may repoint it
    # as an ephemeral overlay.
    home.activation.omanixThemeState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${omanixLib.state.rootExpr}/current"
      run ln -sfn "${themesStore}/${config.omanix.theme}" \
        "${omanixLib.state.rootExpr}/current/theme"
      # Best-effort live apply; must never fail activation whether or not the
      # shell is running (a cold start already reads current/theme on launch).
      run sh -c '
        _t="${omanixLib.state.rootExpr}/current/theme"
        if command -v omanix-shell >/dev/null 2>&1; then
          _c=$(${pkgs.coreutils}/bin/base64 -w0 < "$_t/colors.toml" 2>/dev/null || true)
          _s=$(${pkgs.coreutils}/bin/base64 -w0 < "$_t/shell.toml" 2>/dev/null || true)
          omanix-shell -q shell applyTheme "$_c" "$_s" || true
        fi'
    '';
  };
}
