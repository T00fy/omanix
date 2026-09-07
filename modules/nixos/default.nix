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
    ./security.nix
    ./hardware.nix
    ./steam.nix
    ./libreoffice.nix
    ./docker.nix
    ./sunshine.nix
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
    sunshine.dummyDisplay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Add a Sunshine "Desktop" application that streams a dedicated dummy
          display instead of one of your real monitors, matching a specific
          client's aspect ratio.

          The problem this solves: streaming a real monitor whose aspect
          ratio doesn't match the client (e.g. a 16:9 desktop monitor streamed
          to a 16:10 laptop) causes letterboxing (black bars). This trades a
          free GPU output port and a cheap "dummy plug" / EDID-emulator HDMI
          or DisplayPort adapter (~$10-30, sold for cloud-gaming/headless
          rigs) for a real display Sunshine can capture with full hardware
          video encoding, at whatever resolution the dummy plug's EDID
          advertises.

          This is a niche feature — you need a spare, genuinely unused GPU
          output port and a dummy plug in it. Most Omanix users streaming to
          a client with the same aspect ratio as their monitor don't need
          this at all; use `omanix.sunshine.scaledDesktop` instead if your
          only problem is text/UI being too small on the client.

          A Hyprland *headless* virtual output (no physical dummy plug) was
          investigated as a way to avoid buying hardware, but was ruled out:
          Sunshine's Wayland capture can only get a plain CPU-memory (SHM)
          buffer from a headless output, never a GPU-memory (DMA-BUF) handle,
          because headless outputs have no real DRM/KMS backing surface. This
          forces every hardware encoder (vaapi/nvenc/vulkan) to fail with
          "Could not initialize display with the given hw device type",
          falling back to slow CPU/software encoding (libx264) for the whole
          stream. A real dummy plug is a genuine DRM/KMS output, so hardware
          encoding works normally. If you hit that exact log message while
          experimenting with a headless output, this is why — revisit only if
          Sunshine gains headless DMA-BUF support.

          Declaring any Sunshine application makes Sunshine ignore its web-UI
          apps.json, so this feature manages the app list declaratively (same
          caveat as `scaledDesktop`).
        '';
      };
      connector = lib.mkOption {
        type = lib.types.str;
        example = "DP-1";
        description = ''
          Output name of the dummy plug, once plugged into a free GPU port —
          from `hyprctl monitors` (a NEW entry should appear when you plug it
          in). Must be a genuinely unused port, not one of your real
          monitors' connectors.

          WARNING: never add a `video=<this connector>:d` kernel parameter
          to try to keep this connector out of the way at boot (e.g. to stop
          it competing for BIOS/initrd/SDDM greeter output). `:d` sets the
          connector's DRM force state to permanently disconnected for the
          whole session, not just at boot — this feature's prep-cmd tries to
          re-enable the exact same connector every time it streams, and that
          can never succeed against a kernel-level force-off, leaving
          Hyprland/DRM stuck and requiring a hard reboot. If this connector
          is racing a real monitor for boot-time output, fix it by
          physically moving cables to whichever port your firmware already
          prefers, not with `video=:d`.
        '';
      };
      mode = lib.mkOption {
        type = lib.types.str;
        example = "2560x1600@60";
        description = ''
          Mode string (WIDTHxHEIGHT@REFRESH) for the dummy plug. Must be a
          mode the plug's own EDID actually advertises — check with:

            hyprctl monitors -j | jq '.[] | select(.name=="<connector>") | .availableModes'

          Many cheap dummy plugs advertise 16:9 modes only; look through the
          full list for anything already matching your target aspect ratio
          (e.g. a 16:10 mode like 1920x1200 or 2560x1600) before assuming
          you need to flash a custom EDID — several plugs advertise a usable
          non-16:9 mode out of the box.
        '';
      };
      position = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "5120x0";
        description = ''
          Monitor position for the dummy plug. Null computes a default
          placed just past the right edge of the widest `realMonitors`
          layout (sum of their widths), which is always non-overlapping
          regardless of how many real monitors you have. Override only if
          you need a specific value.
        '';
      };
      scale = lib.mkOption {
        type = lib.types.str;
        default = "1";
        description = ''
          Scale factor for the dummy plug. Unlike `scaledDesktop`, this
          feature isn't primarily a scale-up trick — the dummy plug's `mode`
          is already the target resolution/aspect ratio — so this defaults to
          no scaling. Override if you also want DPI scaling on top.
        '';
      };
      sensitivity = lib.mkOption {
        type = lib.types.str;
        default = "0";
        description = ''
          Hyprland `input:sensitivity` applied while a client is connected to
          this app (range -1.0 to 1.0). Defaults to unchanged (0), since a
          dummy plug's resolution is usually close in pixel density to your
          real monitors — unlike `scaledDesktop`'s deliberate 2x, there's
          usually no pointer-speed mismatch to compensate for. Override if
          your dummy plug's resolution differs substantially from your real
          monitors.
        '';
      };
      revertSensitivity = lib.mkOption {
        type = lib.types.str;
        default = "0";
        description = "Hyprland `input:sensitivity` restored on disconnect.";
      };
      cursorSize = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = ''
          Cursor size (`HYPRCURSOR_SIZE`/`XCURSOR_SIZE`) applied while a
          client is connected to this app. Defaults to the normal local size
          (unchanged), for the same reason as `sensitivity` above.
        '';
      };
      revertCursorSize = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Cursor size restored on disconnect.";
      };
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Desktop (MacBook)";
        description = ''
          Name shown in the Moonlight client for this entry. Null uses a
          generic descriptive default, "Desktop (<connector>)" — set this
          explicitly to something meaningful for your setup (e.g.
          "Desktop (MacBook)") if you want a friendlier client-facing name.
        '';
      };
      realMonitors = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                example = "DP-2";
                description = "Real monitor's output name, from `hyprctl monitors`.";
              };
              mode = lib.mkOption {
                type = lib.types.str;
                example = "2560x1440@144";
                description = "Real monitor's normal mode string (WIDTHxHEIGHT@REFRESH).";
              };
              position = lib.mkOption {
                type = lib.types.str;
                example = "0x0";
                description = "Real monitor's normal position, exactly as it should be restored on disconnect.";
              };
              scale = lib.mkOption {
                type = lib.types.str;
                default = "1";
                description = "Real monitor's normal scale factor, exactly as it should be restored on disconnect.";
              };
            };
          }
        );
        example = lib.literalExpression ''
          [
            { name = "DP-2";     mode = "2560x1440@144"; position = "0x0";    }
            { name = "HDMI-A-2"; mode = "2560x1440@144"; position = "2560x0"; }
          ]
        '';
        description = ''
          Your real monitors, disabled while this app streams and re-enabled
          (at exactly these values) on disconnect. Required — this feature
          has no way to discover your real monitor layout on its own.

          These values are also declared for local Hyprland use via
          `omanix.monitors` (a Home Manager option). To avoid retyping them
          in two places, define your monitor list once in your own flake
          (e.g. a small `monitors.nix` exporting a plain Nix list) and import
          it for both `omanix.monitors` and this field, deriving each format
          from the same source values.
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
