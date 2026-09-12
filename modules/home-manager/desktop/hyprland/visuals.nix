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

  scaleNum =
    let
      isNumeric = builtins.match "[0-9.]+" cfg.monitor.scale != null;
    in
    if isNumeric then builtins.fromJSON cfg.monitor.scale else 1.0;
  gdkScale = if scaleNum > 1 then "2" else "1";

  mkLua = lib.generators.mkLuaInline;
in
{
  options.omanix.hyprland.extraSettings = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = ''
      Extra Hyprland settings to merge with the Omanix defaults.
      These are passed directly to wayland.windowManager.hyprland.settings
      and are merged recursively, so you can override or extend any section.

      Example:
        omanix.hyprland.extraSettings = {
          config = {
            general.allow_tearing = true;
            decoration.rounding = 10;
          };
        };
    '';
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";

      settings = lib.recursiveUpdate {
        env = [
          { _args = [ "GDK_SCALE" gdkScale ]; }
        ];

        monitor = [
          {
            _args = [
              (mkLua ''{
                output = "",
                mode = "highres",
                position = "auto",
                scale = "${toString cfg.monitor.scale}",
              }'')
            ];
          }
        ];

        config = {
          general = {
            gaps_in = cfg.hyprland.gaps.inner;
            gaps_out = cfg.hyprland.gaps.outer;
            border_size = cfg.hyprland.border.size;

            col = {
              active_border = "rgb(${colors.stripHash theme.colors.accent})";
              inactive_border = "rgb(${colors.stripHash theme.colors.color8})";
            };

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
              color = "0xee1a1a1a";
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
          };

          xwayland = {
            force_zero_scaling = true;
          };

          dwindle = {
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
            mouse_move_enables_dpms = true;
            key_press_enables_dpms = true;
            # Live-reloading a Lua config tears down and re-executes the whole
            # script, which desyncs __lua keybind dispatch (binds stay listed
            # but stop firing until the session restarts). Suppress the on-save
            # autoreload; config is asserted at session start, not mutated live.
            disable_autoreload = true;
          };
        };

        curve = [
          { _args = [ "easeOutQuint" (mkLua ''{ type = "bezier", points = { {0.23, 1}, {0.32, 1} } }'') ]; }
          { _args = [ "easeInOutCubic" (mkLua ''{ type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } }'') ]; }
          { _args = [ "linear" (mkLua ''{ type = "bezier", points = { {0, 0}, {1, 1} } }'') ]; }
          { _args = [ "almostLinear" (mkLua ''{ type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } }'') ]; }
          { _args = [ "quick" (mkLua ''{ type = "bezier", points = { {0.15, 0}, {0.1, 1} } }'') ]; }
        ];

        animation = [
          { _args = [ (mkLua ''{ leaf = "global", enabled = true, speed = 10, bezier = "default" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" }'') ]; }
          { _args = [ (mkLua ''{ leaf = "workspaces", enabled = false }'') ]; }
        ];
      } cfg.hyprland.extraSettings;
    };

    # Home Manager's default onChange runs `hyprctl reload` on every activation.
    # For a Lua config that reload re-executes the whole script and rebinds the
    # __lua keybind dispatch; in Hyprland 0.56.2 that leaves exec keybinds listed
    # but non-firing until the session is restarted (e.g. Super+Space stops
    # opening the launcher after `rebuild`). Drop the live reload — the config is
    # declarative and applies cleanly on the next Hyprland start / relogin.
    # mkForce is required because onChange is a `lines` option (defs concatenate).
    xdg.configFile."hypr/hyprland.lua".onChange = lib.mkForce ''
      echo "omanix: Hyprland config updated; changes apply on next Hyprland start (relogin)." >&2
    '';
  };
}
