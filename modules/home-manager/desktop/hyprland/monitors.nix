{ config, lib, ... }:
let
  cfg = config.omanix;
  mkLua = lib.generators.mkLuaInline;

  # Shared (Omarchy) mode leaves workspaces global — no monitor pinning, no
  # per-monitor id offset. Only the legacy unique-per-monitor mode pins each
  # monitor's own 1..workspaceCount range at base = idx * 10.
  perMonitor = cfg.hyprland.uniqueWorkspacePerMonitor;

  workspaceRules = lib.flatten (
    lib.imap0 (
      idx: mon:
      let
        base = idx * 10;
      in
      lib.imap1 (
        wsIdx: _:
        {
          _args = [
            (mkLua ''{
              workspace = "${toString (base + wsIdx)}",
              monitor = "${mon.name}"${if wsIdx == 1 then '',
              default = true'' else ""},
            }'')
          ];
        }
      ) (lib.range 1 mon.workspaceCount)
    ) cfg.monitors
  );

  explicitMonitorLines = lib.filter (
    mon: mon.resolution != null || mon.refreshRate != null || mon.position != null || mon.disabled
  ) cfg.monitors;

  mkMonitorSpec =
    mon:
    let
      res = if mon.resolution != null then mon.resolution else "highres";
      rate = if mon.refreshRate != null then "@${toString mon.refreshRate}" else "";
      scale = toString cfg.monitor.scale;
      position = if mon.position != null then mon.position else "auto";
    in
    {
      _args = [
        (mkLua ''{
          output = "${mon.name}",
          mode = "${res}${rate}",
          position = "${position}",
          scale = "${scale}",
          disabled = ${if mon.disabled then "true" else "false"},
        }'')
      ];
    };
in
{
  options.omanix.hyprland.uniqueWorkspacePerMonitor = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Workspace model across monitors.

      false (default) — shared workspaces (Omarchy behavior): one global set of
      workspaces 1-5 shared across every monitor. Super+N focuses global
      workspace N wherever you are (pulling it to the focused monitor), and
      every bar shows the same set, highlighting the single focused workspace.

      true — unique workspace per monitor (legacy Omanix): each monitor gets its
      own independent 1-5, pinned to that output (real ids 10*monitorIndex + N).
      Super+N focuses the focused monitor's Nth workspace, and each bar shows and
      highlights only its own monitor's workspaces.
    '';
  };

  options.omanix.monitors = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Monitor name (e.g., DP-2, HDMI-A-1). Use `hyprctl monitors` to find yours.";
            example = "DP-2";
          };
          resolution = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Override resolution (e.g., \"2560x1440\"). Null = use Hyprland preferred.";
            example = "2560x1440";
          };
          refreshRate = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Override refresh rate in Hz (e.g., 144). Null = use Hyprland preferred.";
            example = 144;
          };
          position = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Explicit monitor position (e.g., "0x0"). Null = "auto" (Hyprland
              lays out monitors automatically in declaration order).

              Note that ALL monitors using "auto" (i.e. every monitor with this
              left null) are re-flowed together whenever any monitor's enabled
              state or mode changes — for example, a script that temporarily
              disables/enables an unrelated output (see
              `omanix.sunshine.dummyDisplay`) can silently shift every
              "auto"-positioned monitor to a new position. If you use any
              feature that toggles monitors at runtime, set explicit positions
              here for your real monitors so they stay put.
            '';
            example = "0x0";
          };
          workspaceCount = lib.mkOption {
            type = lib.types.int;
            default = 5;
            description = "Number of workspaces for this monitor (default: 5).";
          };
          disabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Start this monitor disabled at boot. Use for an output that
              should be completely inert during normal local use — for
              example, a dummy plug used only by
              `omanix.sunshine.dummyDisplay`, so it's never reachable via
              workspace switching or the mouse until that feature's prep-cmd
              explicitly enables it. Still needs a `workspaceCount` entry
              here so its workspace range is reserved and doesn't collide
              with another monitor's, even while disabled.
            '';
          };
        };
      }
    );
    default = [ ];
    description = ''
      Configure monitors for workspace management and display settings.
      Each monitor gets its own set of workspaces (1-5 by default).
      Press Super+1-5 to access workspaces on the currently focused monitor.

      Setting resolution, refreshRate, or position generates an explicit
      Hyprland monitor line for that display. Monitors without any of these
      set fall through to the catch-all line in visuals.nix (highres, auto
      scale, auto position).

      Set explicit positions if you use any feature that toggles monitors at
      runtime (e.g. `omanix.sunshine.dummyDisplay`), since Hyprland's "auto"
      position re-flows every auto-positioned monitor whenever any monitor's
      state changes.

      Example:
        omanix.monitors = [
          { name = "DP-2";     resolution = "2560x1440"; refreshRate = 144; position = "0x0"; }
          { name = "HDMI-A-2"; resolution = "2560x1440"; refreshRate = 144; position = "2560x0"; }
        ];
    '';
  };

  config = lib.mkIf (cfg.monitors != [ ]) {
    wayland.windowManager.hyprland.settings = lib.mkMerge [
      (lib.mkIf perMonitor { workspace_rule = workspaceRules; })
      (lib.mkIf (explicitMonitorLines != [ ]) {
        monitor = map mkMonitorSpec explicitMonitorLines;
      })
    ];
  };
}
