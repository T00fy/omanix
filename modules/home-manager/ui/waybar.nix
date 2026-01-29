{
  config,
  pkgs,
  lib,
  ...
}:
let
  theme = config.omarchy.activeTheme;
  cfg = config.omarchy;
  waybarCfg = config.omarchy.waybar;

  # --- DYNAMIC WORKSPACE LOGIC ---
  
  # 1. Generate persistent workspaces map: { "DP-2" = [1 2 3 4 5]; "HDMI-A-2" = [6 7 8 9 10]; }
  # This uses the 'omarchy.monitors' option we defined.
  persistentWs = lib.listToAttrs (map (m: {
    name = m.name;
    value = m.workspaces;
  }) cfg.monitors);

  # 2. Generate icon mapping (The Visual Trick)
  # Maps actual ID to (ID-1 % 5) + 1. 
  # This makes WS 1 -> "1", WS 6 -> "1", WS 11 -> "1" etc.
  wsIcons = lib.listToAttrs (map (ws: {
    name = toString ws;
    value = toString (lib.mod (ws - 1) 5 + 1);
  }) (lib.range 1 20)) // {
    active = "󱓻";
    default = "";
  };
in
{
  options.omarchy.waybar = {
    modules-left = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "custom/omarchy" "hyprland/workspaces" ];
      description = "Modules to display on the left side of waybar";
    };

    modules-center = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "clock" ];
      description = "Modules to display in the center of waybar";
    };

    modules-right = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "group/tray-expander"
        "bluetooth"
        "network"
        "pulseaudio"
        "battery"
      ];
      description = "Modules to display on the right side of waybar";
    };
  };

  config = {
    programs.waybar = {
      enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 0;

          modules-left = waybarCfg.modules-left;
          modules-center = waybarCfg.modules-center;
          modules-right = waybarCfg.modules-right;

          "hyprland/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            # Only show workspaces assigned to the monitor this bar is on
            all-outputs = false; 
            format-icons = wsIcons;
            persistent-workspaces = persistentWs;
          };

          "custom/omarchy" = {
            format = "<span font='omarchy'>\ue900</span>";
            on-click = "omarchy-menu";
            tooltip-format = "Omarchy Menu";
          };

          clock = {
            format = "{:%a %H:%M}";
            format-alt = "{:%d %b %Y}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
          };

          network = {
            format-wifi = "{icon}";
            format-ethernet = "󰀂";
            format-disconnected = "󰤮";
            format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
          };

          pulseaudio = {
            format = "{icon}";
            format-muted = "";
            format-icons = {
              headphone = "";
              default = [ "" "" "" ];
            };
            on-click = "pavucontrol";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-icons = {
              charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
              default = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            };
          };

          bluetooth = {
            format = "";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            on-click = "blueman-manager";
          };

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 600;
              children-class = "tray-group-item";
            };
            modules = [ "custom/expand-icon" "tray" ];
          };

          "custom/expand-icon" = {
            format = "";
            tooltip = false;
          };

          tray = {
            icon-size = 12;
            spacing = 17;
          };
        };
      };

      style = ''
        @define-color background ${theme.colors.background};
        @define-color foreground ${theme.colors.foreground};
        @define-color accent ${theme.colors.accent};

        * {
          background-color: @background;
          color: @foreground;
          border: none;
          border-radius: 0;
          min-height: 0;
          font-family: 'omarchy', '${cfg.font}'; 
          font-size: 13px;
        }

        .modules-left { margin-left: 8px; }
        .modules-right { margin-right: 8px; }

        #workspaces button {
          all: initial;
          padding: 0 6px;
          margin: 0 1.5px;
          min-width: 9px;
        }

        /* Dim empty workspaces like Omarchy */
        #workspaces button.empty { opacity: 0.5; }
        
        /* Highlight active workspace square */
        #workspaces button.active { color: @accent; }

        #cpu, #battery, #pulseaudio, #custom-omarchy, #tray {
          min-width: 12px;
          margin: 0 7.5px;
        }

        #tray { margin-right: 16px; }
        #bluetooth { margin-right: 17px; }
        #network { margin-right: 13px; }
        #custom-expand-icon { margin-right: 18px; }

        #clock {
          font-family: '${cfg.font}';
          min-width: 150px;
          margin-left: 8.75px;
        }
      '';
    };
  };
}
