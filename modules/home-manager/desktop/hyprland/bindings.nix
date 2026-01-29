{ config, pkgs, ... }:
let
  # OSD client command that targets the focused monitor
  osdClient = ''swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"'';
in
{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    
    # ═══════════════════════════════════════════════════════════════════
    # APP LAUNCHERS
    # ═══════════════════════════════════════════════════════════════════
    "$terminal" = "ghostty";
    "$fileManager" = "nautilus --new-window";
    "$browser" = "omarchy-launch-browser";
    "$music" = "spotify"; 
    
    # Note: $messenger variable removed as you requested removing the bindings for Signal/Google
    
    bind = [
      # ─────────────────────────────────────────────────────────────────
      # App Launchers (Strict Omarchy Defaults)
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, RETURN, exec, $terminal"
      "$mainMod SHIFT, F, exec, $fileManager"
      "$mainMod SHIFT, B, exec, $browser"
      "$mainMod SHIFT ALT, B, exec, omarchy-launch-browser --private"
      
      # Restored 'SHIFT' to match Omarchy manual
      "$mainMod SHIFT, M, exec, $music"
      "$mainMod SHIFT, N, exec, $terminal -e nvim"
      "$mainMod SHIFT, D, exec, $terminal -e lazydocker"
      
      # Per your request: Obsidian on Super+Shift+O
      "$mainMod SHIFT, O, exec, obsidian -disable-gpu" 
      
      # ─────────────────────────────────────────────────────────────────
      # Clipboard
      # ─────────────────────────────────────────────────────────────────
      "$mainMod, C, sendshortcut, CTRL, Insert,"
      "$mainMod, V, sendshortcut, SHIFT, Insert,"
      "$mainMod, X, sendshortcut, CTRL, X,"
      "$mainMod CTRL, V, exec, omarchy-launch-walker -m clipboard"
      
      # ─────────────────────────────────────────────────────────────────
      # Window Management
      # ─────────────────────────────────────────────────────────────────
      # Close windows
      "$mainMod, W, killactive"
      "CTRL ALT, DELETE, exec, omarchy-hyprland-window-close-all"
      
      # Control tiling - Restored Omarchy defaults
      "$mainMod, J, togglesplit"
      "$mainMod, P, pseudo"
      "$mainMod, T, togglefloating"  # Restored: T is for Tiling/Floating
      "$mainMod, F, fullscreen, 0"
      "$mainMod CTRL, F, fullscreenstate, 0 2"
      "$mainMod ALT, F, fullscreen, 1"
      "$mainMod, code:32, exec, omarchy-hyprland-window-pop" # O key - Pop window
      
      # Move focus with arrow keys
      "$mainMod, LEFT, movefocus, l"
      "$mainMod, RIGHT, movefocus, r"
      "$mainMod, UP, movefocus, u"
      "$mainMod, DOWN, movefocus, d"

      # Switch workspaces with number keys
      "$mainMod, code:10, workspace, 1"
      "$mainMod, code:11, workspace, 2"
      "$mainMod, code:12, workspace, 3"
      "$mainMod, code:13, workspace, 4"
      "$mainMod, code:14, workspace, 5"
      "$mainMod, code:15, workspace, 6"
      "$mainMod, code:16, workspace, 7"
      "$mainMod, code:17, workspace, 8"
      "$mainMod, code:18, workspace, 9"
      "$mainMod, code:19, workspace, 10"

      # Move active window to workspace
      "$mainMod SHIFT, code:10, movetoworkspace, 1"
      "$mainMod SHIFT, code:11, movetoworkspace, 2"
      "$mainMod SHIFT, code:12, movetoworkspace, 3"
      "$mainMod SHIFT, code:13, movetoworkspace, 4"
      "$mainMod SHIFT, code:14, movetoworkspace, 5"
      "$mainMod SHIFT, code:15, movetoworkspace, 6"
      "$mainMod SHIFT, code:16, movetoworkspace, 7"
      "$mainMod SHIFT, code:17, movetoworkspace, 8"
      "$mainMod SHIFT, code:18, movetoworkspace, 9"
      "$mainMod SHIFT, code:19, movetoworkspace, 10"

      # Move window silently to workspace
      "$mainMod SHIFT ALT, code:10, movetoworkspacesilent, 1"
      "$mainMod SHIFT ALT, code:11, movetoworkspacesilent, 2"
      "$mainMod SHIFT ALT, code:12, movetoworkspacesilent, 3"
      "$mainMod SHIFT ALT, code:13, movetoworkspacesilent, 4"
      "$mainMod SHIFT ALT, code:14, movetoworkspacesilent, 5"
      "$mainMod SHIFT ALT, code:15, movetoworkspacesilent, 6"
      "$mainMod SHIFT ALT, code:16, movetoworkspacesilent, 7"
      "$mainMod SHIFT ALT, code:17, movetoworkspacesilent, 8"
      "$mainMod SHIFT ALT, code:18, movetoworkspacesilent, 9"
      "$mainMod SHIFT ALT, code:19, movetoworkspacesilent, 10"

      # Scratchpad
      "$mainMod, S, togglespecialworkspace, scratchpad"
      "$mainMod ALT, S, movetoworkspacesilent, special:scratchpad"

      # TAB between workspaces
      "$mainMod, TAB, workspace, e+1"
      "$mainMod SHIFT, TAB, workspace, e-1"
      "$mainMod CTRL, TAB, workspace, previous"

      # Move workspaces to other monitors
      "$mainMod SHIFT ALT, LEFT, movecurrentworkspacetomonitor, l"
      "$mainMod SHIFT ALT, RIGHT, movecurrentworkspacetomonitor, r"
      "$mainMod SHIFT ALT, UP, movecurrentworkspacetomonitor, u"
      "$mainMod SHIFT ALT, DOWN, movecurrentworkspacetomonitor, d"

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
      "$mainMod, code:20, resizeactive, -100 0"    # - key
      "$mainMod, code:21, resizeactive, 100 0"     # = key
      "$mainMod SHIFT, code:20, resizeactive, 0 -100"
      "$mainMod SHIFT, code:21, resizeactive, 0 100"

      # Scroll through workspaces
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"

      # Groups
      "$mainMod, code:42, togglegroup" # G key
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
      # Menus
      "$mainMod, SPACE, exec, omarchy-launch-walker"
      "$mainMod CTRL, E, exec, omarchy-launch-walker -m symbols"
      "$mainMod ALT, SPACE, exec, omarchy-menu"
      "$mainMod, ESCAPE, exec, omarchy-menu system"
      "$mainMod, K, exec, omarchy-menu-keybindings"
      ", XF86Calculator, exec, gnome-calculator"

      # Aesthetics
      "$mainMod SHIFT, SPACE, exec, omarchy-toggle-waybar"
      "$mainMod CTRL, SPACE, exec, omarchy-theme-bg-next"
      # Removed: Theme picker (Super+Ctrl+Shift+Space)
      ''$mainMod, BACKSPACE, exec, hyprctl dispatch setprop "address:$(hyprctl activewindow -j | jq -r '.address')" opaque toggle''
      "$mainMod SHIFT, BACKSPACE, exec, omarchy-hyprland-workspace-toggle-gaps"

      # Notifications
      "$mainMod, COMMA, exec, makoctl dismiss"
      "$mainMod SHIFT, COMMA, exec, makoctl dismiss --all"
      "$mainMod CTRL, COMMA, exec, makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send 'Silenced notifications' || notify-send 'Enabled notifications'"
      "$mainMod ALT, COMMA, exec, makoctl invoke"
      "$mainMod SHIFT ALT, COMMA, exec, makoctl restore"

      # Toggle idle/nightlight
      "$mainMod CTRL, I, exec, omarchy-toggle-idle"
      "$mainMod CTRL, N, exec, omarchy-toggle-nightlight"

      # Removed: Apple Display brightness controls (Ctrl + F1/F2)

      # Captures
      ", PRINT, exec, omarchy-cmd-screenshot"
      "SHIFT, PRINT, exec, omarchy-cmd-screenshot smart clipboard"
      "ALT, PRINT, exec, omarchy-menu screenrecord"
      "$mainMod, PRINT, exec, pkill hyprpicker || hyprpicker -a"

      # File sharing
      "$mainMod CTRL, S, exec, omarchy-menu share"

      # Waybar-less info
      ''$mainMod CTRL ALT, T, exec, notify-send "    $(date +"%A %H:%M  —  %d %B W%V %Y")"''
      ''$mainMod CTRL ALT, B, exec, notify-send "󰁹    Battery is at $(omarchy-battery-remaining)%"''

      # Control panels (btop moved here to match Omarchy)
      "$mainMod CTRL, A, exec, omarchy-launch-audio"
      "$mainMod CTRL, B, exec, omarchy-launch-bluetooth"
      "$mainMod CTRL, W, exec, omarchy-launch-wifi"
      "$mainMod CTRL, T, exec, omarchy-launch-tui btop"

      # Lock system
      "$mainMod CTRL, L, exec, omarchy-lock-screen"
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
      # Precise 1% adjustments with Alt
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
      "$mainMod, XF86AudioMute, exec, omarchy-cmd-audio-switch"
      ", XF86PowerOff, exec, omarchy-menu system"
    ];

    # Removed: Dictation bindings (bindd / binddr)
  };
}
