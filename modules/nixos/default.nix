{ config, lib, pkgs, ... }:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;
  availableThemes = builtins.attrNames omanixLib.themes;
in
{
  imports = [
    ./hyprland.nix
    ./login.nix
    ./plymouth.nix
    ./browser-policy.nix
    ./security.nix
    ./hardware.nix
    ./idle.nix
    ./steam.nix
    ./libreoffice.nix
    ./docker.nix
    ./sunshine.nix
    ./tailscale.nix
  ];

  options.omanix = {
    enable = lib.mkEnableOption "Omanix desktop environment";

    theme = lib.mkOption {
      type = lib.types.enum availableThemes;
      default = "tokyo-night";
      description = ''
        The active Omanix theme. This setting is inherited by Home Manager
        when using Home Manager as a NixOS module.

        Available themes: ${lib.concatStringsSep ", " availableThemes}
      '';
      example = "tokyo-night";
    };

    wallpaperIndex = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Index of the wallpaper to use from the theme's wallpaper list.";
    };

    wallpaperOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Override the theme's wallpaper with a specific local file (takes priority over index).";
    };

    activeTheme = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      description = "The fully resolved theme data (read-only, computed from omanix.theme)";
    };

    steam.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Steam and gaming tools (requires omanix.enable).";
    };
    docker.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Docker daemon.";
    };
    sunshine.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Sunshine game streaming server (requires omanix.enable).";
    };
    sunshine.allowedIps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of IPs or CIDR subnets allowed to connect to Sunshine (e.g. [\"192.168.1.0/24\"]).";
    };
    sunshine.scaledDesktop = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Add a Sunshine "Desktop" application whose prep-cmd temporarily
          raises the host Hyprland scale for the streamed monitor while a
          Moonlight client is connected, then reverts it on disconnect.

          Useful when the host runs at 1x scale for local use but its UI is
          too small to read when streamed to a smaller client display. The
          scale change is live (via `hyprctl keyword monitor`) and leaves the
          normal local experience untouched.

          Declaring any Sunshine application makes Sunshine ignore its web-UI
          apps.json, so this feature manages the app list declaratively.
        '';
      };
      monitor = lib.mkOption {
        type = lib.types.str;
        example = "DP-2";
        description = ''
          Output name of the monitor Sunshine streams (from `hyprctl monitors`,
          or the "[wlgrab] Selected monitor" line in Sunshine's log).
        '';
      };
      mode = lib.mkOption {
        type = lib.types.str;
        example = "2560x1440@144";
        description = ''
          Physical mode string (WIDTHxHEIGHT@REFRESH) for the streamed monitor.
          Kept identical between the scaled and reverted states so only the
          scale factor changes.
        '';
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        example = "0x0";
        description = ''
          Monitor position passed to `hyprctl keyword monitor`. Use the exact
          position from `hyprctl monitors` (e.g. "0x0") so the revert restores
          the original layout rather than letting Hyprland re-auto-place it.
        '';
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "2.0";
        example = "2.0";
        description = ''
          Scale factor applied while a client is connected. Prefer factors that
          divide the resolution to a whole number (e.g. 2.0 or 1.25 on 2560x1440)
          to avoid Hyprland nudging the scale and softening the image.
        '';
      };
      revertScale = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = ''
          Scale factor restored on disconnect. Should match the monitor's
          normal local scale (usually the value of `omanix.monitor.scale`).
        '';
      };
      sensitivity = lib.mkOption {
        type = lib.types.str;
        default = "-0.5";
        example = "-0.5";
        description = ''
          Hyprland `input:sensitivity` applied while a client is connected
          (range -1.0 to 1.0). Moonlight maps the client's pointer motion
          onto the streamed monitor's logical (post-scale) resolution, so
          doubling the monitor scale via `scale` makes the same physical
          trackpad/mouse movement cover proportionally more logical
          distance, making the cursor feel too fast. Lower this to
          compensate so pointer speed while streaming matches local use.
        '';
      };
      revertSensitivity = lib.mkOption {
        type = lib.types.str;
        default = "0";
        description = ''
          Hyprland `input:sensitivity` restored on disconnect. Should match
          the monitor's normal local sensitivity (Hyprland's own default is
          0, and `omanix.hyprland`/`input.nix` does not override it).
        '';
      };
      cursorSize = lib.mkOption {
        type = lib.types.int;
        default = 12;
        example = 12;
        description = ''
          Cursor size (`HYPRCURSOR_SIZE`/`XCURSOR_SIZE`) applied while a
          client is connected. The cursor bitmap is rendered at this nominal
          size multiplied by the monitor's scale factor, so it grows right
          along with everything else when `scale` doubles the monitor —
          halving it here (e.g. 12, for a normal size of 24 at `scale =
          "2.0"`) keeps the cursor's on-screen size unchanged while streaming.
        '';
      };
      revertCursorSize = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = ''
          Cursor size restored on disconnect. Should match the monitor's
          normal local cursor size (`HYPRCURSOR_SIZE`/`XCURSOR_SIZE` in
          `modules/home-manager/desktop/hyprland/envs.nix`, default 24).
        '';
      };
      scaledName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Desktop (Scaled)";
        description = ''
          Name shown in the Moonlight client for the scaled entry. Null uses a
          descriptive default that includes the scale factor and monitor, e.g.
          "Desktop (Scaled 2.0x — DP-2)".
        '';
      };
      nativeName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Desktop (Native)";
        description = ''
          Name shown in the Moonlight client for the unscaled companion entry.
          Null uses a descriptive default that includes the monitor, e.g.
          "Desktop (Native — DP-2)". Pick this entry when the client drives an
          external display that does not need UI enlargement.
        '';
      };
    };
    sunshine.extraApps = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      description = ''
        Additional Sunshine application entries (passed verbatim to
        `services.sunshine.applications.apps`). Use this to declare apps like
        "Steam Big Picture" alongside the generated scaled Desktop entry, so the
        whole app list stays reproducible rather than living in the web UI.
      '';
      example = lib.literalExpression ''
        [
          {
            name = "Steam Big Picture";
            detached = [ "setsid steam steam://open/bigpicture" ];
            image-path = "steam.png";
          }
        ]
      '';
    };
    devenv.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install the devenv CLI system-wide (requires omanix.enable).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    # Numtide binary cache for llm-agents.nix packages (Claude Code, OpenCode).
    # The default overlay builds against llm-agents' pinned nixpkgs, so these
    # cache hits avoid rebuilding the prebuilt agent binaries locally.
    nix.settings = {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    omanix.activeTheme =
      let
        baseTheme = omanixLib.themes.${cfg.theme};
        selectedWallpaper =
          if cfg.wallpaperOverride != null then
            cfg.wallpaperOverride
          else if builtins.length baseTheme.assets.wallpapers > cfg.wallpaperIndex then
            builtins.elemAt baseTheme.assets.wallpapers cfg.wallpaperIndex
          else
            builtins.elemAt baseTheme.assets.wallpapers 0;
      in
      baseTheme
      // {
        assets = baseTheme.assets // {
          wallpaper = selectedWallpaper;
        };
      };

    # ═══════════════════════════════════════════════════════════════════
    # FONT CONFIGURATION
    # ═══════════════════════════════════════════════════════════════════
    fonts.fontconfig = {
      antialias = true;
      hinting = {
        enable = true;
        autohint = false;
        style = "slight";
      };
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };

    # ═══════════════════════════════════════════════════════════════════
    # HARDWARE
    # ═══════════════════════════════════════════════════════════════════
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # ═══════════════════════════════════════════════════════════════════
    # SERVICES
    # ═══════════════════════════════════════════════════════════════════
    services.blueman.enable = true;

    # ═══════════════════════════════════════════════════════════════════
    # SYSTEM PACKAGES
    # ═══════════════════════════════════════════════════════════════════
    # devenv CLI — available system-wide for users who want it (not used by
    # Omanix itself).
    environment.systemPackages = lib.optionals cfg.devenv.enable [ pkgs.devenv ];

    # ═══════════════════════════════════════════════════════════════════
    # PROGRAMS
    # ═══════════════════════════════════════════════════════════════════
    programs.zsh.enable = true;
  };
}
