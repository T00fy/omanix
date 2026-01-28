{ config, lib, omarchyLib, ... }:
let
  theme = config.omarchy.activeTheme;
  colors = omarchyLib.colors;
  cfg = config.omarchy;
in
{
  wayland.windowManager.hyprland = {
    # FIX 1: Enable Hyprland so config is generated
    enable = true;
    
    settings = {
      env = [
        "GDK_SCALE,${toString cfg.monitor.scale}"
      ];
      monitor = ",highres,auto,${toString cfg.monitor.scale}";
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        
        "col.active_border" = "rgb(${colors.stripHash theme.colors.accent})";
        "col.inactive_border" = "rgb(${colors.stripHash theme.colors.color8})";
        
        layout = "dwindle";
        resize_on_border = false;
        allow_tearing = false;
      };

      decoration = {
          rounding = 0;
      
          # Shadow config
          shadow = {
            enabled = true;
            range = 2;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          # Blur config
          blur = {
            enabled = true;
            size = 2;
            passes = 2;
            special = true;
            brightness = 0.6; # Number
            contrast = 0.75; # Number
          };
      };
      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 0, 0, ease"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      master = {
        new_status = "master";
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };
  };
}
