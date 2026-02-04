{ config, ... }:
let
  cfg = config.omanix;
  osdClient = ''swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"'';
  musicCommand = if cfg.apps.spotatui.enable then "omanix-launch-tui-spotatui" else "spotify";
in
{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";

    # ═══════════════════════════════════════════════════════════════════
    # APP LAUNCHERS
    # ═══════════════════════════════════════════════════════════════════
    "$terminal" = "ghostty";
    "$fileManager" = "nautilus --new-window";
    "$browser" = "omanix-launch-browser";
    "$music" = musicCommand;

    # ═══════════════════════════════════════════════════════════════════
    # BINDINGS WITH DESCRIPTIONS (bindd)
    # Max 30 char descriptions for clean menu display
    # ═══════════════════════════════════════════════════════════════════
    bindd = [
      # ─────────────────────────────────────────────────────────────────
      # App Launchers
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, RETURN, Open Terminal, exec, $terminal"
      "$mainMod SHIFT, F, Open File Manager, exec, $fileManager"
      "$mainMod SHIFT, B, Open Browser, exec, $browser"
      "$mainMod SHIFT ALT, B, Open Private Browser, exec, omanix-launch-browser --private"
      "$mainMod SHIFT, M, Open Music Player, exec, $music"
      "$mainMod SHIFT, N, Open Neovim, exec, $terminal -e nvim"
      "$mainMod SHIFT, D, Open Lazydocker, exec, $terminal -e lazydocker"
      "$mainMod SHIFT, O, Open Obsidian, exec, obsidian -disable-gpu"

      # ─────────────────────────────────────────────────────────────────
      # Clipboard
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, C, Copy, sendshortcut, CTRL, Insert,"
      "$mainMod, V, Paste, sendshortcut, SHIFT, Insert,"
      "$mainMod, X, Cut, sendshortcut, CTRL, X,"
      "$mainMod CTRL, V, Clipboard History, exec, omanix-launch-walker -m clipboard"

      # ─────────────────────────────────────────────────────────────────
      # Window Management
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, W, Close Window, killactive"
      "CTRL ALT, DELETE, Close All Windows, exec, omanix-hyprland-window-close-all"

      "$mainMod, J, Toggle Split Direction, togglesplit"
      "$mainMod, P, Toggle Pseudo-tile, pseudo"
      "$mainMod, T, Toggle Floating, togglefloating"
      "$mainMod, F, Fullscreen, fullscreen, 0"
      "$mainMod CTRL, F, Fullscreen (Keep Bar), fullscreenstate, 0 2"
      "$mainMod ALT, F, Maximize Window, fullscreen, 1"
      "$mainMod, code:32, Pop Window Out, exec, omanix-hyprland-window-pop"

      # Move focus
      "$mainMod, LEFT, Focus Left, movefocus, l"
      "$mainMod, RIGHT, Focus Right, movefocus, r"
      "$mainMod, UP, Focus Up, movefocus, u"
      "$mainMod, DOWN, Focus Down, movefocus, d"

      # ─────────────────────────────────────────────────────────────────
      # Workspace Management (Monitor-Aware)
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, code:10, Workspace 1, exec, omanix-workspace 1"
      "$mainMod, code:11, Workspace 2, exec, omanix-workspace 2"
      "$mainMod, code:12, Workspace 3, exec, omanix-workspace 3"
      "$mainMod, code:13, Workspace 4, exec, omanix-workspace 4"
      "$mainMod, code:14, Workspace 5, exec, omanix-workspace 5"

      "$mainMod SHIFT, code:10, Move to Workspace 1, exec, omanix-workspace 1 move"
      "$mainMod SHIFT, code:11, Move to Workspace 2, exec, omanix-workspace 2 move"
      "$mainMod SHIFT, code:12, Move to Workspace 3, exec, omanix-workspace 3 move"
      "$mainMod SHIFT, code:13, Move to Workspace 4, exec, omanix-workspace 4 move"
      "$mainMod SHIFT, code:14, Move to Workspace 5, exec, omanix-workspace 5 move"

      "$mainMod SHIFT ALT, code:10, Send to Workspace 1, exec, omanix-workspace 1 movesilent"
      "$mainMod SHIFT ALT, code:11, Send to Workspace 2, exec, omanix-workspace 2 movesilent"
      "$mainMod SHIFT ALT, code:12, Send to Workspace 3, exec, omanix-workspace 3 movesilent"
      "$mainMod SHIFT ALT, code:13, Send to Workspace 4, exec, omanix-workspace 4 movesilent"
      "$mainMod SHIFT ALT, code:14, Send to Workspace 5, exec, omanix-workspace 5 movesilent"

      # ─────────────────────────────────────────────────────────────────
      # Multi-Monitor Management
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, bracketright, Focus Next Monitor, focusmonitor, +1"
      "$mainMod, bracketleft, Focus Prev Monitor, focusmonitor, -1"
      "$mainMod SHIFT, bracketright, Window to Next Monitor, movewindow, mon:+1"
      "$mainMod SHIFT, bracketleft, Window to Prev Monitor, movewindow, mon:-1"

      # ─────────────────────────────────────────────────────────────────
      # Scratchpad
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, S, Toggle Scratchpad, togglespecialworkspace, scratchpad"
      "$mainMod ALT, S, Send to Scratchpad, movetoworkspacesilent, special:scratchpad"

      # ─────────────────────────────────────────────────────────────────
      # Workspace Navigation
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, TAB, Next Workspace, workspace, e+1"
      "$mainMod SHIFT, TAB, Previous Workspace, workspace, e-1"
      "$mainMod CTRL, TAB, Last Workspace, workspace, previous"

      # Swap windows
      "$mainMod SHIFT, LEFT, Swap Window Left, swapwindow, l"
      "$mainMod SHIFT, RIGHT, Swap Window Right, swapwindow, r"
      "$mainMod SHIFT, UP, Swap Window Up, swapwindow, u"
      "$mainMod SHIFT, DOWN, Swap Window Down, swapwindow, d"

      # Cycle windows
      "ALT, TAB, Cycle Windows, cyclenext"
      "ALT SHIFT, TAB, Cycle Windows Reverse, cyclenext, prev"

      # Resize
      "$mainMod, code:20, Shrink Width, resizeactive, -100 0"
      "$mainMod, code:21, Grow Width, resizeactive, 100 0"
      "$mainMod SHIFT, code:20, Shrink Height, resizeactive, 0 -100"
      "$mainMod SHIFT, code:21, Grow Height, resizeactive, 0 100"

      # ─────────────────────────────────────────────────────────────────
      # Groups
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, code:42, Toggle Group, togglegroup"
      "$mainMod ALT, code:42, Ungroup Window, moveoutofgroup"
      "$mainMod ALT, LEFT, Group with Left, moveintogroup, l"
      "$mainMod ALT, RIGHT, Group with Right, moveintogroup, r"
      "$mainMod ALT, UP, Group with Above, moveintogroup, u"
      "$mainMod ALT, DOWN, Group with Below, moveintogroup, d"
      "$mainMod ALT, TAB, Next in Group, changegroupactive, f"
      "$mainMod ALT SHIFT, TAB, Prev in Group, changegroupactive, b"
      "$mainMod CTRL, LEFT, Prev in Group, changegroupactive, b"
      "$mainMod CTRL, RIGHT, Next in Group, changegroupactive, f"
      "$mainMod ALT, code:10, Group Tab 1, changegroupactive, 1"
      "$mainMod ALT, code:11, Group Tab 2, changegroupactive, 2"
      "$mainMod ALT, code:12, Group Tab 3, changegroupactive, 3"
      "$mainMod ALT, code:13, Group Tab 4, changegroupactive, 4"
      "$mainMod ALT, code:14, Group Tab 5, changegroupactive, 5"

      # ─────────────────────────────────────────────────────────────────
      # Launchers & Menus
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, SPACE, App Launcher, exec, omanix-launch-walker"
      "$mainMod CTRL, E, Symbol Picker, exec, omanix-launch-walker -m symbols"
      "$mainMod ALT, SPACE, Main Menu, exec, omanix-menu"
      "$mainMod, ESCAPE, System Menu, exec, omanix-menu system"
      "$mainMod, K, Show Keybindings, exec, omanix-menu-keybindings"
      ", XF86Calculator, Calculator, exec, gnome-calculator"

      # ─────────────────────────────────────────────────────────────────
      # Aesthetics
      # ─────────────────────────────────────────────────────────────────
      "$mainMod SHIFT, SPACE, Toggle Waybar, exec, omanix-toggle-waybar"
      "$mainMod CTRL, SPACE, Next Wallpaper, exec, omanix-theme-bg-next"
      ''$mainMod, BACKSPACE, Toggle Opacity, exec, hyprctl dispatch setprop "address:$(hyprctl activewindow -j | jq -r '.address')" opaque toggle''
      "$mainMod SHIFT, BACKSPACE, Toggle Gaps, exec, omanix-hyprland-workspace-toggle-gaps"

      # ─────────────────────────────────────────────────────────────────
      # Notifications
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, COMMA, Dismiss Notification, exec, makoctl dismiss"
      "$mainMod SHIFT, COMMA, Dismiss All Notifs, exec, makoctl dismiss --all"
      "$mainMod CTRL, COMMA, Toggle Do Not Disturb, exec, makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send 'Silenced notifications' || notify-send 'Enabled notifications'"
      "$mainMod ALT, COMMA, Action on Notif, exec, makoctl invoke"
      "$mainMod SHIFT ALT, COMMA, Restore Last Notif, exec, makoctl restore"

      # ─────────────────────────────────────────────────────────────────
      # System Toggles
      # ─────────────────────────────────────────────────────────────────
      "$mainMod CTRL, I, Toggle Idle Inhibit, exec, omanix-toggle-idle"
      "$mainMod CTRL, N, Toggle Night Light, exec, omanix-toggle-nightlight"

      # ─────────────────────────────────────────────────────────────────
      # Screenshots & Screen Recording
      # ─────────────────────────────────────────────────────────────────
      ", PRINT, Screenshot, exec, omanix-cmd-screenshot"
      "SHIFT, PRINT, Screenshot to Clipboard, exec, omanix-cmd-screenshot smart clipboard"
      "ALT, PRINT, Screen Record Menu, exec, omanix-menu screenrecord"
      "$mainMod, PRINT, Color Picker, exec, pkill hyprpicker || hyprpicker -a"

      # ─────────────────────────────────────────────────────────────────
      # File Sharing
      # ─────────────────────────────────────────────────────────────────
      "$mainMod CTRL, S, Share Menu, exec, omanix-menu share"

      # ─────────────────────────────────────────────────────────────────
      # Quick Info (No Waybar)
      # ─────────────────────────────────────────────────────────────────
      ''$mainMod CTRL ALT, T, Show Time, exec, notify-send "    $(date +"%A %H:%M  —  %d %B W%V %Y")"''
      ''$mainMod CTRL ALT, B, Show Battery, exec, notify-send "󰁹    Battery is at $(omanix-battery-remaining)%"''

      # ─────────────────────────────────────────────────────────────────
      # Control Panels
      # ─────────────────────────────────────────────────────────────────
      "$mainMod CTRL, A, Audio Settings, exec, omanix-launch-audio"
      "$mainMod CTRL, B, Bluetooth Settings, exec, omanix-launch-bluetooth"
      "$mainMod CTRL, W, WiFi Settings, exec, omanix-launch-wifi"
      "$mainMod CTRL, T, System Monitor, exec, omanix-launch-tui btop"

      # ─────────────────────────────────────────────────────────────────
      # Lock & Power
      # ─────────────────────────────────────────────────────────────────
      "$mainMod CTRL, L, Lock Screen, exec, omanix-lock-screen"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Mouse bindings
    # ═══════════════════════════════════════════════════════════════════
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Media keys with repeat + descriptions (binddel)
    # ═══════════════════════════════════════════════════════════════════
    binddel = [
      ", XF86AudioRaiseVolume, Volume Up, exec, ${osdClient} --output-volume raise"
      ", XF86AudioLowerVolume, Volume Down, exec, ${osdClient} --output-volume lower"
      ", XF86AudioMute, Toggle Mute, exec, ${osdClient} --output-volume mute-toggle"
      ", XF86AudioMicMute, Toggle Mic Mute, exec, ${osdClient} --input-volume mute-toggle"
      ", XF86MonBrightnessUp, Brightness Up, exec, ${osdClient} --brightness raise"
      ", XF86MonBrightnessDown, Brightness Down, exec, ${osdClient} --brightness lower"
      "ALT, XF86AudioRaiseVolume, Volume Up (Fine), exec, ${osdClient} --output-volume +1"
      "ALT, XF86AudioLowerVolume, Volume Down (Fine), exec, ${osdClient} --output-volume -1"
      "ALT, XF86MonBrightnessUp, Brightness Up (Fine), exec, ${osdClient} --brightness +1"
      "ALT, XF86MonBrightnessDown, Brightness Down (Fine), exec, ${osdClient} --brightness -1"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Media keys locked + descriptions (binddl)
    # ═══════════════════════════════════════════════════════════════════
    binddl = [
      ", XF86AudioNext, Next Track, exec, ${osdClient} --playerctl next"
      ", XF86AudioPause, Play/Pause, exec, ${osdClient} --playerctl play-pause"
      ", XF86AudioPlay, Play/Pause, exec, ${osdClient} --playerctl play-pause"
      ", XF86AudioPrev, Previous Track, exec, ${osdClient} --playerctl previous"
      "$mainMod, XF86AudioMute, Switch Audio Output, exec, omanix-cmd-audio-switch"
      ", XF86PowerOff, Power Menu, exec, omanix-menu system"
    ];
  };
}
