# modules/home-manager/desktop/hyprland/monitors.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;
  
  # Script to move window to same-numbered workspace on target monitor
  moveToMonitor = pkgs.writeShellScriptBin "omanix-move-to-monitor" ''
    export PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:$PATH"
    
    DIRECTION="$1"  # +1, -1, or monitor name
    
    # Get current workspace ID and extract the local number (1-5)
    CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')
    CURRENT_MON=$(hyprctl activeworkspace -j | jq -r '.monitor')
    
    # Find target monitor
    if [[ "$DIRECTION" =~ ^[+-] ]]; then
      TARGET_MON=$(hyprctl monitors -j | jq -r --arg cur "$CURRENT_MON" --arg dir "$DIRECTION" '
        map(.name) | 
        to_entries | 
        (map(select(.value == $cur)) | .[0].key) as $idx |
        length as $len |
        if $dir == "+1" then
          .[($idx + 1) % $len].value
        else
          .[($idx - 1 + $len) % $len].value
        end
      ')
    else
      TARGET_MON="$DIRECTION"
    fi
    
    [ -z "$TARGET_MON" ] || [ "$TARGET_MON" = "$CURRENT_MON" ] && exit 0
    
    # Move window to the target monitor (Hyprland handles workspace)
    hyprctl dispatch movewindow "mon:$TARGET_MON"
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
        workspaces = lib.mkOption {
          type = lib.types.int;
          default = 5;
          description = "Number of workspaces for this monitor (default: 5).";
        };
        position = lib.mkOption {
          type = lib.types.enum [ "left" "right" "above" "below" "auto" ];
          default = "auto";
          description = "Logical position for directional focus/movement.";
        };
      };
    });
    default = [];
    description = ''
      Configure monitors with independent workspace sets.
      Each monitor gets its own workspaces 1-N.
      
      Example:
        omanix.monitors = [
          { name = "DP-2"; workspaces = 5; position = "left"; }
          { name = "HDMI-A-1"; workspaces = 5; position = "right"; }
          { name = "DP-3"; workspaces = 3; position = "above"; }
        ];
    '';
  };

  config = lib.mkIf (cfg.monitors != []) {
    home.packages = [ moveToMonitor ];

    wayland.windowManager.hyprland.settings = {
      # Bind each workspace to its monitor
      workspace = lib.flatten (
        lib.imap0 (monIdx: mon:
          let
            # Calculate workspace ID offset for this monitor
            prevWorkspaces = lib.foldl' (acc: m: acc + m.workspaces) 0 
              (lib.take monIdx cfg.monitors);
          in
          lib.genList (wsIdx: 
            let
              wsId = prevWorkspaces + wsIdx + 1;
              isDefault = wsIdx == 0;
            in
            "${toString wsId}, monitor:${mon.name}, default:${if isDefault then "true" else "false"}"
          ) mon.workspaces
        ) cfg.monitors
      );

      # Bind workspace keys to "workspace N on current monitor"
      bind = let
        maxWorkspaces = lib.foldl' (a: b: if a > b then a else b) 0 
          (map (m: m.workspaces) cfg.monitors);
        
        # Generate workspace switching binds
        workspaceBinds = lib.flatten (lib.genList (i: 
          let 
            wsNum = i + 1;
            key = if wsNum == 10 then "code:19" else "code:${toString (9 + wsNum)}";
          in [
            # Switch to workspace N on current monitor
            "$mainMod, ${key}, exec, omanix-workspace ${toString wsNum}"
            # Move window to workspace N on current monitor
            "$mainMod SHIFT, ${key}, exec, omanix-move-to-workspace ${toString wsNum}"
            # Move silently
            "$mainMod SHIFT ALT, ${key}, exec, omanix-move-to-workspace-silent ${toString wsNum}"
          ]
        ) maxWorkspaces);

        # Monitor focus binds based on position
        monitorFocusBinds = lib.flatten (map (mon:
          let
            dirKey = {
              "left" = "LEFT";
              "right" = "RIGHT"; 
              "above" = "UP";
              "below" = "DOWN";
            }.${mon.position} or null;
          in
          lib.optionals (dirKey != null) [
            "$mainMod ALT, ${dirKey}, focusmonitor, ${mon.name}"
          ]
        ) cfg.monitors);

      in workspaceBinds ++ monitorFocusBinds ++ [
        # Cycle through monitors
        "$mainMod, grave, focusmonitor, +1"
        "$mainMod SHIFT, grave, focusmonitor, -1"
        
        # Move window to next/prev monitor
        "$mainMod CTRL, grave, exec, omanix-move-to-monitor +1"
        "$mainMod CTRL SHIFT, grave, exec, omanix-move-to-monitor -1"
        
        # Direct movement by direction (alternative to cycling)
        "$mainMod SHIFT, bracketright, movewindow, mon:+1"
        "$mainMod SHIFT, bracketleft, movewindow, mon:-1"
      ];
    };
  };
}
