{ config, lib, ... }:
let
  cfg = config.omarchy;
  
  # Generate workspace binding rules from monitor config
  workspaceBindings = lib.flatten (
    map (mon: 
      map (ws: "${toString ws}, monitor:${mon.name}, default:${
        if ws == builtins.head mon.workspaces then "true" else "false"
      }") mon.workspaces
    ) cfg.monitors
  );
in
{
  options.omarchy.monitors = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Monitor name (e.g., DP-2, HDMI-A-1). Use `hyprctl monitors` to find yours.";
          example = "DP-2";
        };
        workspaces = lib.mkOption {
          type = lib.types.listOf lib.types.int;
          description = "List of workspace numbers to bind to this monitor.";
          example = [ 1 2 3 4 5 ];
        };
      };
    });
    default = [];
    description = ''
      Configure monitor-specific workspace bindings.
      Each monitor gets its own set of workspaces.
      Use `hyprctl monitors` to find your monitor names.
      
      Example for dual monitors:
        omarchy.monitors = [
          { name = "DP-2"; workspaces = [ 1 2 3 4 5 ]; }
          { name = "HDMI-A-2"; workspaces = [ 6 7 8 9 10 ]; }
        ];
    '';
    example = [
      { name = "DP-2"; workspaces = [ 1 2 3 4 5 ]; }
      { name = "HDMI-A-2"; workspaces = [ 6 7 8 9 10 ]; }
    ];
  };

  config = lib.mkIf (cfg.monitors != []) {
    wayland.windowManager.hyprland.settings = {
      # Bind workspaces to specific monitors
      workspace = workspaceBindings;
    };
  };
}
