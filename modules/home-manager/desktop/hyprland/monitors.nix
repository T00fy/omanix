{ config, lib, ... }:
let
  cfg = config.omanix;

  workspaceRules = lib.flatten (
    lib.imap0 (idx: mon:
      let
        base = idx * 10;
      in
      lib.imap1 (wsIdx: _: 
        "${toString (base + wsIdx)}, monitor:${mon.name}${if wsIdx == 1 then ", default:true" else ""}"
      ) (lib.range 1 mon.workspaceCount)
    ) cfg.monitors
  );
in
{
  options.omanix.monitors = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Monitor name (e.g., DP-2, HDMI-A-1). Use `hyprctl monitors` to find yours.";
          example = "DP-2";
        };
        workspaceCount = lib.mkOption {
          type = lib.types.int;
          default = 5;
          description = "Number of workspaces for this monitor (default: 5).";
        };
      };
    });
    default = [];
    description = ''
      Configure monitors for workspace management.
      Each monitor gets its own set of workspaces (1-5 by default).
      Press Super+1-5 to access workspaces on the currently focused monitor.
      
      Example:
        omanix.monitors = [
          { name = "DP-2"; }           # Gets workspaces 1-5
          { name = "HDMI-A-2"; }       # Gets workspaces 11-15
        ];
    '';
  };

  config = lib.mkIf (cfg.monitors != []) {
    wayland.windowManager.hyprland.settings = {
      workspace = workspaceRules;
    };
  };
}
