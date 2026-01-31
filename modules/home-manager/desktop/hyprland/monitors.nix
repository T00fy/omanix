{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;

  # Generate workspace rules that bind workspaces to monitors
  # Each monitor gets workspaces: base + 1, base + 2, ..., base + 5
  # Monitor 1: workspaces 1-5, Monitor 2: workspaces 11-15, Monitor 3: workspaces 21-25, etc.
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

  # Script to switch to workspace N on the currently focused monitor
  workspaceSwitcher = pkgs.writeShellScriptBin "omanix-workspace" ''
    WORKSPACE_NUM="$1"
    ACTION="''${2:-switch}"  # switch, move, or movesilent
    
    # Get the focused monitor name
    FOCUSED_MONITOR=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')
    
    # Determine the workspace base for this monitor
    # Monitor config is passed as environment or we detect from workspace bindings
    case "$FOCUSED_MONITOR" in
      ${lib.concatStringsSep "\n      " (lib.imap0 (idx: mon: 
        ''${mon.name}) BASE=${toString (idx * 10)} ;;''
      ) cfg.monitors)}
      *) BASE=0 ;;
    esac
    
    TARGET_WORKSPACE=$((BASE + WORKSPACE_NUM))
    
    case "$ACTION" in
      switch)
        ${pkgs.hyprland}/bin/hyprctl dispatch workspace "$TARGET_WORKSPACE"
        ;;
      move)
        ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE"
        ;;
      movesilent)
        ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspacesilent "$TARGET_WORKSPACE"
        ;;
    esac
  '';

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
    home.packages = [ workspaceSwitcher ];

    wayland.windowManager.hyprland.settings = {
      workspace = workspaceRules;
    };
  };
}
