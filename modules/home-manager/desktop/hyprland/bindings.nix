{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    
    bind = [
      # Apps
      "$mainMod, RETURN, exec, ghostty"
      "$mainMod SHIFT, F, exec, nautilus --new-window"
      "$mainMod SHIFT, B, exec, omarchy-launch-browser"
      "$mainMod SHIFT ALT, B, exec, omarchy-launch-browser --private"
      
      # Windows
      "$mainMod, W, killactive"
      "$mainMod, V, togglefloating"
      "$mainMod, P, pseudo"
      "$mainMod, J, togglesplit"
      "$mainMod, F, fullscreen, 0"
      "$mainMod CTRL, F, fullscreenstate, 0 2"

      # Focus
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Workspaces
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      # Move Active
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Utilities
      ", PRINT, exec, omarchy-cmd-screenshot smart file"
      "SHIFT, PRINT, exec, omarchy-cmd-screenshot smart clipboard"
      "$mainMod, PRINT, exec, hyprpicker -a"
      "$mainMod SHIFT, SPACE, exec, pkill -SIGUSR1 waybar"
      "$mainMod, SPACE, exec, wofi --show drun"
    ];

    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    bindel = [
      ",XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
      ",XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
      ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
      ",XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
      ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
      ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
    ];
  };
}
