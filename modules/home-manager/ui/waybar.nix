{
  config,
  pkgs,
  lib,
  ...
}:
let
  theme = config.omarchy.activeTheme;
  cfg = config.omarchy.waybar;
in
{
  options.omarchy.waybar = {
    modules-left = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "hyprland/workspaces" ];
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
        "tray"
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

          modules-left = cfg.modules-left;
          modules-center = cfg.modules-center;
          modules-right = cfg.modules-right;
          "hyprland/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "0";
              active = "󱓻";
              default = "";
            };
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
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            tooltip-format-wifi = "{essid} ({signalStrength}%)";
          };

          pulseaudio = {
            format = "{icon}";
            format-muted = "";
            format-icons = {
              headphone = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-icons = {
              charging = [
                "󰢜"
                "󰂆"
                "󰂇"
                "󰂈"
                "󰢝"
                "󰂉"
                "󰢞"
                "󰂊"
                "󰂋"
                "󰂅"
              ];
              default = [
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
            };
          };

          bluetooth = {
            format = "";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            on-click = "blueman-manager";
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
          font-family: 'omarchy', '${config.omarchy.font}'; 
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

        #workspaces button.empty { opacity: 0.5; }

        #cpu, #battery, #pulseaudio, #custom-omarchy, 
        #custom-screenrecording-indicator, #custom-update {
          min-width: 12px;
          margin: 0 7.5px;
        }

        #tray { margin-right: 16px; }
        #bluetooth { margin-right: 17px; }
        #network { margin-right: 13px; }
        #custom-expand-icon { margin-right: 18px; }

        tooltip { padding: 2px; }
        #custom-update { font-size: 10px; }
        #clock {
          font-family: '${config.omarchy.font}';
          min-width: 150px;
          margin-left: 8.75px;
        }
        .hidden { opacity: 0; }

        #custom-screenrecording-indicator {
          min-width: 12px;
          margin-left: 5px;
          font-size: 10px;
          padding-bottom: 1px;
        }
        #custom-screenrecording-indicator.active { color: #a55555; }

        #custom-voxtype {
          min-width: 12px;
          margin: 0 0 0 7.5px;
        }
        #custom-voxtype.recording { color: #a55555; }
      '';
    };

  };
}
