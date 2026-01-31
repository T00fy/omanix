{ config, pkgs, ... }:
let
  # OSD client command that targets the focused monitor
  osdClient = ''swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"'';
  
  # Check if multi-monitor setup is configured
  hasMultiMonitor = config.omanix.monitors != [];
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
    "$music" = "spotify"; 
    
    bind = [
      # ─────────────────────────────────────────────────────────────────
      # App Launchers
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, RETURN, exec, $terminal"
      "$mainMod SHIFT, F, exec, $fileManager"
      "$mainMod SHIFT, B, exec, $browser"
      "$mainMod SHIFT ALT, B, exec, omanix-launch-browser --private"
      "$mainMod SHIFT, M, exec, $music"
      "$mainMod SHIFT, N, exec, $terminal -e nvim"
      "$mainMod SHIFT, D, exec, $terminal -e lazydocker"
      "$mainMod SHIFT, O, exec, obsidian -disable-gpu" 
      
      # ─────────────────────────────────────────────────────────────────
      # Clipboard
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, C, sendshortcut, CTRL, Insert,"
      "$mainMod, V, sendshortcut, SHIFT, Insert,"
      "$mainMod, X, sendshortcut, CTRL, X,"
      "$mainMod CTRL, V, exec, omanix-launch-walker -m clipboard"
      
      # ─────────────────────────────────────────────────────────────────
      # Window Management
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, W, killactive"
      "CTRL ALT, DELETE, exec, omanix-hyprland-window-close-all"
      
      "$mainMod, J, togglesplit"
      "$mainMod, P, pseudo"
      "$mainMod, T, togglefloating"
      "$mainMod, F, fullscreen, 0"
      "$mainMod CTRL, F, fullscreenstate, 0 2"
      "$mainMod ALT, F, fullscreen, 1"
      "$mainMod, code:32, exec, omanix-hyprland-window-pop"
      
      # Move focus with arrow keys
      "$mainMod, LEFT, movefocus, l"
      "$mainMod, RIGHT, movefocus, r"
      "$mainMod, UP, movefocus, u"
      "$mainMod, DOWN, movefocus, d"

      # ─────────────────────────────────────────────────────────────────
      # Workspace Management (Monitor-Aware)
      # Super+1-5 goes to workspace 1-5 on the CURRENT monitor
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, code:10, exec, omanix-workspace 1"
      "$mainMod, code:11, exec, omanix-workspace 2"
      "$mainMod, code:12, exec, omanix-workspace 3"
      "$mainMod, code:13, exec, omanix-workspace 4"
      "$mainMod, code:14, exec, omanix-workspace 5"

      # Move window to workspace on CURRENT monitor
      "$mainMod SHIFT, code:10, exec, omanix-workspace 1 move"
      "$mainMod SHIFT, code:11, exec, omanix-workspace 2 move"
      "$mainMod SHIFT, code:12, exec, omanix-workspace 3 move"
      "$mainMod SHIFT, code:13, exec, omanix-workspace 4 move"
      "$mainMod SHIFT, code:14, exec, omanix-workspace 5 move"

      # Move window silently to workspace on CURRENT monitor
      "$mainMod SHIFT ALT, code:10, exec, omanix-workspace 1 movesilent"
      "$mainMod SHIFT ALT, code:11, exec, omanix-workspace 2 movesilent"
      "$mainMod SHIFT ALT, code:12, exec, omanix-workspace 3 movesilent"
      "$mainMod SHIFT ALT, code:13, exec, omanix-workspace 4 movesilent"
      "$mainMod SHIFT ALT, code:14, exec, omanix-workspace 5 movesilent"

      # ─────────────────────────────────────────────────────────────────
      # Multi-Monitor Management
      # ─────────────────────────────────────────────────────────────────
      # Focus next/previous monitor (cycles)
      "$mainMod, bracketright, focusmonitor, +1"
      "$mainMod, bracketleft, focusmonitor, -1"
      
      # Move window to next/previous monitor
      "$mainMod SHIFT, bracketright, movewindow, mon:+1"
      "$mainMod SHIFT, bracketleft, movewindow, mon:-1"

      # ─────────────────────────────────────────────────────────────────
      # Scratchpad
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, S, togglespecialworkspace, scratchpad"
      "$mainMod ALT, S, movetoworkspacesilent, special:scratchpad"

      # ─────────────────────────────────────────────────────────────────
      # Workspace Navigation
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, TAB, workspace, e+1"
      "$mainMod SHIFT, TAB, workspace, e-1"
      "$mainMod CTRL, TAB, workspace, previous"

      # Swap windows
      "$mainMod SHIFT, LEFT, swapwindow, l"
      "$mainMod SHIFT, RIGHT, swapwindow, r"
      "$mainMod SHIFT, UP, swapwindow, u"
      "$mainMod SHIFT, DOWN, swapwindow, d"

      # Cycle through windows on workspace
      "ALT, TAB, cyclenext"
      "ALT SHIFT, TAB, cyclenext, prev"
      "ALT, TAB, bringactivetotop"
      "ALT SHIFT, TAB, bringactivetotop"

      # Resize active window
      "$mainMod, code:20, resizeactive, -100 0"
      "$mainMod, code:21, resizeactive, 100 0"
      "$mainMod SHIFT, code:20, resizeactive, 0 -100"
      "$mainMod SHIFT, code:21, resizeactive, 0 100"

      # Scroll through workspaces
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"

      # ─────────────────────────────────────────────────────────────────
      # Groups
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, code:42, togglegroup"
      "$mainMod ALT, code:42, moveoutofgroup"
      "$mainMod ALT, LEFT, moveintogroup, l"
      "$mainMod ALT, RIGHT, moveintogroup, r"
      "$mainMod ALT, UP, moveintogroup, u"
      "$mainMod ALT, DOWN, moveintogroup, d"
      "$mainMod ALT, TAB, changegroupactive, f"
      "$mainMod ALT SHIFT, TAB, changegroupactive, b"
      "$mainMod CTRL, LEFT, changegroupactive, b"
      "$mainMod CTRL, RIGHT, changegroupactive, f"
      "$mainMod ALT, mouse_down, changegroupactive, f"
      "$mainMod ALT, mouse_up, changegroupactive, b"
      "$mainMod ALT, code:10, changegroupactive, 1"
      "$mainMod ALT, code:11, changegroupactive, 2"
      "$mainMod ALT, code:12, changegroupactive, 3"
      "$mainMod ALT, code:13, changegroupactive, 4"
      "$mainMod ALT, code:14, changegroupactive, 5"

      # ─────────────────────────────────────────────────────────────────
      # Utilities
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, SPACE, exec, omanix-launch-walker"
      "$mainMod CTRL, E, exec, omanix-launch-walker -m symbols"
      "$mainMod ALT, SPACE, exec, omanix-menu"
      "$mainMod, ESCAPE, exec, omanix-menu system"
      "$mainMod, K, exec, omanix-menu-keybindings"
      ", XF86Calculator, exec, gnome-calculator"

      # Aesthetics
      "$mainMod SHIFT, SPACE, exec, omanix-toggle-waybar"
      "$mainMod CTRL, SPACE, exec, omanix-theme-bg-next"
      ''$mainMod, BACKSPACE, exec, hyprctl dispatch setprop "address:$(hyprctl activewindow -j | jq -r '.address')" opaque toggle''
      "$mainMod SHIFT, BACKSPACE, exec, omanix-hyprland-workspace-toggle-gaps"

      # Notifications
      "$mainMod, COMMA, exec, makoctl dismiss"
      "$mainMod SHIFT, COMMA, exec, makoctl dismiss --all"
      "$mainMod CTRL, COMMA, exec, makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send 'Silenced notifications' || notify-send 'Enabled notifications'"
      "$mainMod ALT, COMMA, exec, makoctl invoke"
      "$mainMod SHIFT ALT, COMMA, exec, makoctl restore"

      # Toggle idle/nightlight
      "$mainMod CTRL, I, exec, omanix-toggle-idle"
      "$mainMod CTRL, N, exec, omanix-toggle-nightlight"

      # Captures
      ", PRINT, exec, omanix-cmd-screenshot"
      "SHIFT, PRINT, exec, omanix-cmd-screenshot smart clipboard"
      "ALT, PRINT, exec, omanix-menu screenrecord"
      "$mainMod, PRINT, exec, pkill hyprpicker || hyprpicker -a"

      # File sharing
      "$mainMod CTRL, S, exec, omanix-menu share"

      # Waybar-less info
      ''$mainMod CTRL ALT, T, exec, notify-send "    $(date +"%A %H:%M  —  %d %B W%V %Y")"''
      ''$mainMod CTRL ALT, B, exec, notify-send "󰁹    Battery is at $(omanix-battery-remaining)%"''

      # Control panels
      "$mainMod CTRL, A, exec, omanix-launch-audio"
      "$mainMod CTRL, B, exec, omanix-launch-bluetooth"
      "$mainMod CTRL, W, exec, omanix-launch-wifi"
      "$mainMod CTRL, T, exec, omanix-launch-tui btop"

      # Lock system
      "$mainMod CTRL, L, exec, omanix-lock-screen"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Mouse bindings
    # ═══════════════════════════════════════════════════════════════════
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Media keys with repeat (bindel)
    # ═══════════════════════════════════════════════════════════════════
    bindel = [
      ", XF86AudioRaiseVolume, exec, ${osdClient} --output-volume raise"
      ", XF86AudioLowerVolume, exec, ${osdClient} --output-volume lower"
      ", XF86AudioMute, exec, ${osdClient} --output-volume mute-toggle"
      ", XF86AudioMicMute, exec, ${osdClient} --input-volume mute-toggle"
      ", XF86MonBrightnessUp, exec, ${osdClient} --brightness raise"
      ", XF86MonBrightnessDown, exec, ${osdClient} --brightness lower"
      "ALT, XF86AudioRaiseVolume, exec, ${osdClient} --output-volume +1"
      "ALT, XF86AudioLowerVolume, exec, ${osdClient} --output-volume -1"
      "ALT, XF86MonBrightnessUp, exec, ${osdClient} --brightness +1"
      "ALT, XF86MonBrightnessDown, exec, ${osdClient} --brightness -1"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # Media keys locked (bindl)
    # ═══════════════════════════════════════════════════════════════════
    bindl = [
      ", XF86AudioNext, exec, ${osdClient} --playerctl next"
      ", XF86AudioPause, exec, ${osdClient} --playerctl play-pause"
      ", XF86AudioPlay, exec, ${osdClient} --playerctl play-pause"
      ", XF86AudioPrev, exec, ${osdClient} --playerctl previous"
      "$mainMod, XF86AudioMute, exec, omanix-cmd-audio-switch"
      ", XF86PowerOff, exec, omanix-menu system"
    ];
  };
}
