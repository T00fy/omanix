{
  config,
  lib,
  omanixLib,
  ...
}:
let
  theme = config.omanix.activeTheme;
  inherit (omanixLib) colors;
  cfg = config.omanix;
in
{
  options.omanix.hyprland.extraSettings = lib.mkOption {
    # Note: extraWindowRules, extraLayerRules, extraBindings, etc.
    # are defined in rules.nix and bindings.nix respectively.
    # This option covers everything else (general, dwindle, decoration, etc.)
    type = lib.types.attrs;
    default = {};
    description = ''
      Extra Hyprland settings to merge with the Omanix defaults.
      These are passed directly to wayland.windowManager.hyprland.settings
      and are merged recursively, so you can override or extend any section.

      Example:
        omanix.hyprland.extraSettings = {
          dwindle.single_window_aspect_ratio = "1 1";
          general.allow_tearing = true;
          decoration.rounding = 10;
          windowrule = [
            "opacity 1 1, match:class ^(my-app)$"
          ];
        };
    '';
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = lib.recursiveUpdate {
        env = [
          "GDK_SCALE,2"
        ];

        xwayland = {
          force_zero_scaling = true;
        };

        monitor = ",highres,auto,${toString cfg.monitor.scale}";

        general = {
          gaps_in = cfg.hyprland.gaps.inner;
          gaps_out = cfg.hyprland.gaps.outer;
          border_size = cfg.hyprland.border.size;

          "col.active_border" = "rgb(${colors.stripHash theme.colors.accent})";
          "col.inactive_border" = "rgb(${colors.stripHash theme.colors.color8})";

          layout = "dwindle";
          resize_on_border = false;
          allow_tearing = false;
        };

        decoration = {
          inherit (cfg.hyprland) rounding;

          shadow = {
            inherit (cfg.hyprland.shadow) enabled;
            inherit (cfg.hyprland.shadow) range;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          blur = {
            inherit (cfg.hyprland.blur) enabled;
            inherit (cfg.hyprland.blur) size;
            inherit (cfg.hyprland.blur) passes;
            special = true;
            brightness = 0.6;
            contrast = 0.75;
          };
        };

        animations = {
          inherit (cfg.hyprland.animations) enabled;
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

        cursor = {
          hide_on_key_press = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      } cfg.hyprland.extraSettings;
    };
  };
}
