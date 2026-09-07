{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;
  osdClient = ''swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"'';

  mkLua = lib.generators.mkLuaInline;

  mkBind = key: dispatcher: opts:
    { _args = [ (mkLua key) (mkLua dispatcher) ] ++ lib.optional (opts != { }) opts; };

  mkExec = key: cmd: desc:
    mkBind key "hl.dsp.exec_cmd([[${cmd}]])" { description = desc; };

  mkExecLocked = key: cmd: desc:
    mkBind key "hl.dsp.exec_cmd([[${cmd}]])" { description = desc; locked = true; };

  mkExecRepeatLocked = key: cmd: desc:
    mkBind key "hl.dsp.exec_cmd([[${cmd}]])" { description = desc; locked = true; repeating = true; };

  terminal = ''omanix-term --cwd="$(omanix-cmd-terminal-cwd)"'';
  fileManager = ''nautilus --new-window "$(omanix-cmd-terminal-cwd)"'';
  browser = "${cfg.browser.package}/bin/${cfg.browser.bin}";
  browserPrivate = "${cfg.browser.package}/bin/${cfg.browser.bin} ${cfg.browser.privateFlag}";
in
{
  options.omanix = {
    browser = {
      package = lib.mkOption {
        type = lib.types.package;
        default = config.programs.firefox.finalPackage;
        defaultText = lib.literalExpression "config.programs.firefox.finalPackage";
        description = ''
          The browser package to use. Defaults to the Firefox package that
          Home Manager actually installs via `programs.firefox` (the wrapped
          package with the configured profile), rather than the raw
          `pkgs.firefox`. Using the wrapped package avoids a `buildEnv`
          collision between two different `firefox` derivations that both
          provide `bin/firefox`.
        '';
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "firefox";
        description = "Executable name within the browser package's bin directory.";
      };
      privateFlag = lib.mkOption {
        type = lib.types.str;
        default = "--private-window";
        description = "CLI flag to open a private/incognito browser window.";
      };
    };
  };

  options.omanix.hyprland = {
    extraBindings = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "Extra key bindings appended to the Omanix defaults. Use attrset with _args for Lua bind format.";
    };

    extraBinds = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "Extra simple binds appended to the defaults.";
    };

    extraMouseBindings = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "Extra mouse bindings appended to the Omanix defaults.";
    };

    extraMediaBindings = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "Extra media bindings appended to defaults.";
    };

    extraLockedBindings = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = "Extra locked bindings appended to defaults.";
    };
  };

  config = {
    wayland.windowManager.hyprland.settings = {
      mod = { _var = "SUPER"; };

      bind =
        [
          # ─────────────────────────────────────────────────────────────────
          # App Launchers
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + RETURN"'' terminal "Open Terminal")
          (mkExec ''mod .. " + SHIFT + F"'' fileManager "Open File Manager")
          (mkExec ''mod .. " + SHIFT + B"'' browser "Open Browser")
          (mkExec ''mod .. " + SHIFT + ALT + B"'' browserPrivate "Open Private Browser")
          (mkExec ''mod .. " + SHIFT + N"'' "${terminal} -- nvim" "Open Neovim")
          (mkExec ''mod .. " + SHIFT + D"'' "${terminal} -- lazydocker" "Open Lazydocker")
          (mkExec ''mod .. " + SHIFT + O"'' "obsidian -disable-gpu" "Open Obsidian")

          # ─────────────────────────────────────────────────────────────────
          # Clipboard
          # ─────────────────────────────────────────────────────────────────
          (mkBind ''mod .. " + C"'' ''hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" })'' { description = "Copy"; })
          (mkBind ''mod .. " + V"'' ''hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" })'' { description = "Paste"; })
          (mkBind ''mod .. " + X"'' ''hl.dsp.send_shortcut({ mods = "CTRL", key = "X" })'' { description = "Cut"; })
          (mkExec ''mod .. " + CTRL + V"'' "omanix-clipboard-open" "Clipboard History")

          # ─────────────────────────────────────────────────────────────────
          # Window Management
          # ─────────────────────────────────────────────────────────────────
          (mkBind ''mod .. " + W"'' "hl.dsp.window.close()" { description = "Close Window"; })
          (mkExec ''"CTRL + ALT + DELETE"'' "omanix-hyprland-window-close-all" "Close All Windows")

          (mkBind ''mod .. " + J"'' ''hl.dsp.layout("togglesplit")'' { description = "Toggle Split Direction"; })
          (mkBind ''mod .. " + P"'' "hl.dsp.window.pseudo()" { description = "Toggle Pseudo-tile"; })
          (mkBind ''mod .. " + T"'' ''hl.dsp.window.float({ action = "toggle" })'' { description = "Toggle Floating"; })
          (mkBind ''mod .. " + F"'' "hl.dsp.window.fullscreen(0)" { description = "Fullscreen"; })
          (mkBind ''mod .. " + CTRL + F"'' ''hl.dsp.window.fullscreen_state({ internal = 0, client = 2 })'' { description = "Fullscreen (Keep Bar)"; })
          (mkBind ''mod .. " + ALT + F"'' "hl.dsp.window.fullscreen(1)" { description = "Maximize Window"; })
          (mkExec ''mod .. " + code:32"'' "omanix-hyprland-window-pop" "Pop Window Out")

          # Move focus
          (mkBind ''mod .. " + LEFT"'' ''hl.dsp.focus({ direction = "left" })'' { description = "Focus Left"; })
          (mkBind ''mod .. " + RIGHT"'' ''hl.dsp.focus({ direction = "right" })'' { description = "Focus Right"; })
          (mkBind ''mod .. " + UP"'' ''hl.dsp.focus({ direction = "up" })'' { description = "Focus Up"; })
          (mkBind ''mod .. " + DOWN"'' ''hl.dsp.focus({ direction = "down" })'' { description = "Focus Down"; })

          # ─────────────────────────────────────────────────────────────────
          # Workspace Management (Monitor-Aware)
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + code:10"'' "omanix-workspace 1" "Workspace 1")
          (mkExec ''mod .. " + code:11"'' "omanix-workspace 2" "Workspace 2")
          (mkExec ''mod .. " + code:12"'' "omanix-workspace 3" "Workspace 3")
          (mkExec ''mod .. " + code:13"'' "omanix-workspace 4" "Workspace 4")
          (mkExec ''mod .. " + code:14"'' "omanix-workspace 5" "Workspace 5")

          (mkExec ''mod .. " + SHIFT + code:10"'' "omanix-workspace 1 move" "Move to Workspace 1")
          (mkExec ''mod .. " + SHIFT + code:11"'' "omanix-workspace 2 move" "Move to Workspace 2")
          (mkExec ''mod .. " + SHIFT + code:12"'' "omanix-workspace 3 move" "Move to Workspace 3")
          (mkExec ''mod .. " + SHIFT + code:13"'' "omanix-workspace 4 move" "Move to Workspace 4")
          (mkExec ''mod .. " + SHIFT + code:14"'' "omanix-workspace 5 move" "Move to Workspace 5")

          (mkExec ''mod .. " + SHIFT + ALT + code:10"'' "omanix-workspace 1 movesilent" "Send to Workspace 1")
          (mkExec ''mod .. " + SHIFT + ALT + code:11"'' "omanix-workspace 2 movesilent" "Send to Workspace 2")
          (mkExec ''mod .. " + SHIFT + ALT + code:12"'' "omanix-workspace 3 movesilent" "Send to Workspace 3")
          (mkExec ''mod .. " + SHIFT + ALT + code:13"'' "omanix-workspace 4 movesilent" "Send to Workspace 4")
          (mkExec ''mod .. " + SHIFT + ALT + code:14"'' "omanix-workspace 5 movesilent" "Send to Workspace 5")

          # ─────────────────────────────────────────────────────────────────
          # Multi-Monitor Management
          # ─────────────────────────────────────────────────────────────────
          (mkBind ''mod .. " + bracketright"'' ''hl.dsp.focus({ monitor = "+1" })'' { description = "Focus Next Monitor"; })
          (mkBind ''mod .. " + bracketleft"'' ''hl.dsp.focus({ monitor = "-1" })'' { description = "Focus Prev Monitor"; })
          (mkBind ''mod .. " + SHIFT + bracketright"'' ''hl.dsp.window.move({ monitor = "+1" })'' { description = "Window to Next Monitor"; })
          (mkBind ''mod .. " + SHIFT + bracketleft"'' ''hl.dsp.window.move({ monitor = "-1" })'' { description = "Window to Prev Monitor"; })

          # ─────────────────────────────────────────────────────────────────
          # Workspace Navigation
          # ─────────────────────────────────────────────────────────────────
          (mkBind ''mod .. " + TAB"'' ''hl.dsp.focus({ workspace = "e+1" })'' { description = "Next Workspace"; })
          (mkBind ''mod .. " + SHIFT + TAB"'' ''hl.dsp.focus({ workspace = "e-1" })'' { description = "Previous Workspace"; })
          (mkBind ''mod .. " + CTRL + TAB"'' ''hl.dsp.focus({ workspace = "previous" })'' { description = "Last Workspace"; })

          # Swap windows
          (mkBind ''mod .. " + SHIFT + LEFT"'' ''hl.dsp.window.swap({ direction = "left" })'' { description = "Swap Window Left"; })
          (mkBind ''mod .. " + SHIFT + RIGHT"'' ''hl.dsp.window.swap({ direction = "right" })'' { description = "Swap Window Right"; })
          (mkBind ''mod .. " + SHIFT + UP"'' ''hl.dsp.window.swap({ direction = "up" })'' { description = "Swap Window Up"; })
          (mkBind ''mod .. " + SHIFT + DOWN"'' ''hl.dsp.window.swap({ direction = "down" })'' { description = "Swap Window Down"; })

          # Cycle windows
          (mkBind ''"ALT + TAB"'' ''hl.dsp.window.cycle_next()'' { description = "Cycle Windows"; })
          (mkBind ''"ALT + SHIFT + TAB"'' ''hl.dsp.window.cycle_next("prev")'' { description = "Cycle Windows Reverse"; })

          # Resize
          (mkBind ''mod .. " + code:20"'' ''hl.dsp.window.resize({ x = -100, y = 0, relative = true })'' { description = "Shrink Width"; })
          (mkBind ''mod .. " + code:21"'' ''hl.dsp.window.resize({ x = 100, y = 0, relative = true })'' { description = "Grow Width"; })
          (mkBind ''mod .. " + SHIFT + code:20"'' ''hl.dsp.window.resize({ x = 0, y = -100, relative = true })'' { description = "Shrink Height"; })
          (mkBind ''mod .. " + SHIFT + code:21"'' ''hl.dsp.window.resize({ x = 0, y = 100, relative = true })'' { description = "Grow Height"; })

          # ─────────────────────────────────────────────────────────────────
          # Groups
          # ─────────────────────────────────────────────────────────────────
          (mkBind ''mod .. " + code:42"'' "hl.dsp.group.toggle()" { description = "Toggle Group"; })
          (mkBind ''mod .. " + ALT + code:42"'' ''hl.dsp.group.move_window("out")'' { description = "Ungroup Window"; })
          (mkBind ''mod .. " + ALT + LEFT"'' ''hl.dsp.group.move_window("l")'' { description = "Group with Left"; })
          (mkBind ''mod .. " + ALT + RIGHT"'' ''hl.dsp.group.move_window("r")'' { description = "Group with Right"; })
          (mkBind ''mod .. " + ALT + UP"'' ''hl.dsp.group.move_window("u")'' { description = "Group with Above"; })
          (mkBind ''mod .. " + ALT + DOWN"'' ''hl.dsp.group.move_window("d")'' { description = "Group with Below"; })
          (mkBind ''mod .. " + ALT + TAB"'' ''hl.dsp.group.next()'' { description = "Next in Group"; })
          (mkBind ''mod .. " + ALT + SHIFT + TAB"'' ''hl.dsp.group.prev()'' { description = "Prev in Group"; })
          (mkBind ''mod .. " + CTRL + LEFT"'' ''hl.dsp.group.prev()'' { description = "Prev in Group"; })
          (mkBind ''mod .. " + CTRL + RIGHT"'' ''hl.dsp.group.next()'' { description = "Next in Group"; })
          (mkBind ''mod .. " + ALT + code:10"'' ''hl.dsp.group.active({ index = 1 })'' { description = "Group Tab 1"; })
          (mkBind ''mod .. " + ALT + code:11"'' ''hl.dsp.group.active({ index = 2 })'' { description = "Group Tab 2"; })
          (mkBind ''mod .. " + ALT + code:12"'' ''hl.dsp.group.active({ index = 3 })'' { description = "Group Tab 3"; })
          (mkBind ''mod .. " + ALT + code:13"'' ''hl.dsp.group.active({ index = 4 })'' { description = "Group Tab 4"; })
          (mkBind ''mod .. " + ALT + code:14"'' ''hl.dsp.group.active({ index = 5 })'' { description = "Group Tab 5"; })

          # ─────────────────────────────────────────────────────────────────
          # Launchers & Menus
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + SPACE"'' "omanix-menu" "App Launcher")
          (mkExec ''mod .. " + CTRL + E"'' "omanix-menu-emoji" "Emoji Picker")
          (mkExec ''mod .. " + ALT + SPACE"'' "omanix-menu apps" "Apps Menu")
          (mkExec ''mod .. " + ESCAPE"'' "omanix-menu system" "System Menu")
          (mkExec ''mod .. " + K"'' "omanix-menu-keybindings" "Show Keybindings")

          # ─────────────────────────────────────────────────────────────────
          # Aesthetics
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + SHIFT + SPACE"'' "omanix-toggle-bar" "Toggle Bar")
          (mkExec ''mod .. " + CTRL + SPACE"'' "omanix-theme-bg-next" "Next Wallpaper")
          (mkExec ''mod .. " + BACKSPACE"'' "omanix-smart-delete" "Smart Delete Line")
          (mkBind ''mod .. " + CTRL + N"'' ''hl.dsp.window.set_prop({prop = "opaque", value = "toggle"})'' { description = "Toggle Opacity"; })
          (mkExec ''mod .. " + SHIFT + BACKSPACE"'' "omanix-hyprland-workspace-toggle-gaps" "Toggle Gaps")

          # ─────────────────────────────────────────────────────────────────
          # Notifications
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + COMMA"'' "omanix-shell notifications dismissOne" "Dismiss Notification")
          (mkExec ''mod .. " + SHIFT + COMMA"'' "omanix-shell notifications dismissAll" "Dismiss All Notifs")
          (mkExec ''mod .. " + CTRL + COMMA"'' "omanix-shell notifications toggleDnd" "Toggle Do Not Disturb")
          (mkExec ''mod .. " + ALT + COMMA"'' "omanix-shell notifications invokeLast" "Action on Notif")
          (mkExec ''mod .. " + SHIFT + ALT + COMMA"'' "omanix-shell notifications showHistory" "Notification History")

          # ─────────────────────────────────────────────────────────────────
          # System Toggles
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + CTRL + I"'' "omanix-toggle-idle" "Toggle Idle Inhibit")

          # ─────────────────────────────────────────────────────────────────
          # Screenshots & Screen Recording
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''"PRINT"'' "omanix-cmd-screenshot" "Screenshot")
          (mkExec ''"SHIFT + PRINT"'' "omanix-cmd-screenshot smart clipboard" "Screenshot to Clipboard")
          (mkExec ''"ALT + PRINT"'' "omanix-cmd-screenrecord" "Screen Record Toggle")
          (mkExec ''mod .. " + PRINT"'' "pkill hyprpicker || hyprpicker -a" "Color Picker")

          # ─────────────────────────────────────────────────────────────────
          # File Sharing
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + CTRL + S"'' "omanix-menu trigger.share" "Share Menu")

          # ─────────────────────────────────────────────────────────────────
          # Quick Info (No Waybar)
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + CTRL + ALT + T"'' ''notify-send "    $(date +"%A %H:%M  —  %d %B W%V %Y")"'' "Show Time")
          (mkExec ''mod .. " + CTRL + ALT + B"'' ''notify-send "󰁹    Battery is at $(omanix-battery-remaining)%"'' "Show Battery")

          # ─────────────────────────────────────────────────────────────────
          # Control Panels
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + CTRL + A"'' "omanix-shell shell toggle omanix.audio" "Audio Panel")
          (mkExec ''mod .. " + CTRL + B"'' "omanix-shell shell toggle omanix.bluetooth" "Bluetooth Panel")
          (mkExec ''mod .. " + CTRL + W"'' "omanix-shell shell toggle omanix.network" "Network Panel")
          (mkExec ''mod .. " + CTRL + D"'' "omanix-shell shell toggle omanix.monitor" "Display Panel")
          (mkExec ''mod .. " + CTRL + P"'' "omanix-shell shell toggle omanix.power" "Power Panel")
          (mkExec ''mod .. " + CTRL + T"'' "omanix-launch-tui btop" "System Monitor")

          # ─────────────────────────────────────────────────────────────────
          # Lock & Power
          # ─────────────────────────────────────────────────────────────────
          (mkExec ''mod .. " + CTRL + L"'' "omanix-system-lock" "Lock Screen")
        ]
        ++ (
          if cfg.apps.spotify.enable then
            [ (mkExec ''mod .. " + SHIFT + M"'' "omanix-launch-or-focus spotify spotify" "Open Music Player") ]
          else
            [ ]
        )
        ++ cfg.hyprland.extraBindings

        # ─────────────────────────────────────────────────────────────────
        # Mouse bindings
        # ─────────────────────────────────────────────────────────────────
        ++ [
          (mkBind ''mod .. " + mouse:272"'' "hl.dsp.window.drag()" { mouse = true; })
          (mkBind ''mod .. " + mouse:273"'' "hl.dsp.window.resize()" { mouse = true; })
        ]
        ++ cfg.hyprland.extraMouseBindings

        # ─────────────────────────────────────────────────────────────────
        # Media keys (repeat + locked)
        # ─────────────────────────────────────────────────────────────────
        ++ [
          (mkExecRepeatLocked ''"XF86AudioRaiseVolume"'' "${osdClient} --output-volume raise" "Volume Up")
          (mkExecRepeatLocked ''"XF86AudioLowerVolume"'' "${osdClient} --output-volume lower" "Volume Down")
          (mkExecRepeatLocked ''"XF86AudioMute"'' "${osdClient} --output-volume mute-toggle" "Toggle Mute")
          (mkExecRepeatLocked ''"XF86AudioMicMute"'' "${osdClient} --input-volume mute-toggle" "Toggle Mic Mute")
          (mkExecRepeatLocked ''"XF86MonBrightnessUp"'' "${osdClient} --brightness raise" "Brightness Up")
          (mkExecRepeatLocked ''"XF86MonBrightnessDown"'' "${osdClient} --brightness lower" "Brightness Down")
          (mkExecRepeatLocked ''"ALT + XF86AudioRaiseVolume"'' "${osdClient} --output-volume +1" "Volume Up (Fine)")
          (mkExecRepeatLocked ''"ALT + XF86AudioLowerVolume"'' "${osdClient} --output-volume -1" "Volume Down (Fine)")
          (mkExecRepeatLocked ''"ALT + XF86MonBrightnessUp"'' "${osdClient} --brightness +1" "Brightness Up (Fine)")
          (mkExecRepeatLocked ''"ALT + XF86MonBrightnessDown"'' "${osdClient} --brightness -1" "Brightness Down (Fine)")
        ]
        ++ cfg.hyprland.extraMediaBindings

        # ─────────────────────────────────────────────────────────────────
        # Media keys (locked, no repeat)
        # ─────────────────────────────────────────────────────────────────
        ++ [
          (mkExecLocked ''"XF86AudioNext"'' "${osdClient} --playerctl next" "Next Track")
          (mkExecLocked ''"XF86AudioPause"'' "${osdClient} --playerctl play-pause" "Play/Pause")
          (mkExecLocked ''"XF86AudioPlay"'' "${osdClient} --playerctl play-pause" "Play/Pause")
          (mkExecLocked ''"XF86AudioPrev"'' "${osdClient} --playerctl previous" "Previous Track")
          (mkExecLocked ''mod .. " + XF86AudioMute"'' "omanix-cmd-audio-switch" "Switch Audio Output")
          (mkExecLocked ''"XF86PowerOff"'' "omanix-menu system" "Power Menu")
        ]
        ++ cfg.hyprland.extraLockedBindings
        ++ cfg.hyprland.extraBinds;
    };
  };
}
