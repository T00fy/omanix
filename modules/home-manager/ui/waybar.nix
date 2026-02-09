{
  config,
  lib,
  ...
}:
let
  theme = config.omanix.activeTheme;
  cfg = config.omanix.waybar;
  monitorCfg = config.omanix.monitors;

  buildFormatIcons =
    monitors:
    let
      monitorMappings = lib.flatten (
        lib.imap0 (
          idx: mon:
          let
            base = idx * 10;
            count = mon.workspaceCount or 5;
          in
          lib.imap1 (wsIdx: _: {
            name = toString (base + wsIdx);
            value = toString wsIdx;
          }) (lib.range 1 count)
        ) monitors
      );
    in
    (builtins.listToAttrs monitorMappings)
    // {
      active = "󱓻";
      default = "";
    };

  buildPersistentWorkspaces =
    monitors:
    lib.listToAttrs (
      lib.imap0 (
        idx: mon:
        let
          base = idx * 10;
          count = mon.workspaceCount or 5;
        in
        {
          inherit (mon) name;
          value = map (n: base + n) (lib.range 1 count);
        }
      ) monitors
    );

  defaultFormatIcons = {
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
    default = "";
  };

  defaultPersistentWorkspaces = {
    "1" = [ ];
    "2" = [ ];
    "3" = [ ];
    "4" = [ ];
    "5" = [ ];
  };

  formatIcons = if monitorCfg != [ ] then buildFormatIcons monitorCfg else defaultFormatIcons;
  persistentWorkspaces =
    if monitorCfg != [ ] then buildPersistentWorkspaces monitorCfg else defaultPersistentWorkspaces;
in
{
  options.omanix.waybar = {
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
        "custom/screenrecording-indicator"
        "mpris"
        "tray"
        "bluetooth"
        "network"
        "pulseaudio"
        "battery"
      ];
      description = "Modules to display on the right side of waybar";
    };

    extraModuleSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = ''
        Extra module configurations merged into the waybar settings.
        Use this to configure custom modules or override built-in module settings.

        Example:
          omanix.waybar.extraModuleSettings = {
            "custom/weather" = {
              exec = "curl -s 'wttr.in/?format=1'";
              interval = 3600;
            };
            clock = {
              format = "{:%H:%M:%S}";
              interval = 1;
            };
          };
      '';
    };

    extraStyle = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra CSS appended to the waybar stylesheet.
        Theme color variables @background, @foreground, and @accent are available.

        Example:
          omanix.waybar.extraStyle = '''
            #custom-weather {
              color: @accent;
              margin: 0 8px;
            }
          ''';
      '';
    };
  };

  config = {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 0;

          inherit (cfg) modules-left;
          inherit (cfg) modules-center;
          inherit (cfg) modules-right;

          "hyprland/workspaces" = {
            format = "{icon}";
            on-click = "activate";
            format-icons = formatIcons;
            persistent-workspaces = persistentWorkspaces;
            show-special = false;
          };

          "mpris" = {
            format = "{player_icon} {title} - {artist}";
            format-paused = "{status_icon} <i>{title} - {artist}</i>";
            player-icons = {
              default = "";
              spotatui = "";
              spotify = "";
            };
            status-icons = {
              paused = "⏸";
            };
            ignored-players = [
              "firefox"
              "chromium"
              "brave"
            ];
            max-length = 50;
          };
          "custom/screenrecording-indicator" = {
            exec = ''echo "󰑊"'';
            exec-if = ''test -f "''${XDG_RUNTIME_DIR:-/tmp}/omanix-screenrecording"'';
            interval = 2;
            return-type = "";
            signal = 8;
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
            format-muted = "󰝟";
            format-icons = {
              headphone = "󰋋";
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
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
            format = "󰂯";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            on-click = "blueman-manager";
          };
        }
        // cfg.extraModuleSettings;
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
          font-family: 'omanix', '${config.omanix.font}'; 
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

        #cpu, #battery, #pulseaudio, #custom-omanix, 
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
          font-family: '${config.omanix.font}';
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
        #mpris {
          color: @accent;
          margin-right: 15px;
          min-width: 50px;
        }

        #mpris.paused {
          color: @foreground;
          opacity: 0.7;
        }
        #custom-voxtype.recording { color: #a55555; }
      ''
      + lib.optionalString (cfg.extraStyle != "") ''

        /* ═══ User Extra Styles ═══ */
        ${cfg.extraStyle}
      '';
    };
  };
}
