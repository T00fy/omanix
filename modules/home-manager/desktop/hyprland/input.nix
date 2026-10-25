{ config, lib, ... }: {
  options.omanix.hyprland.numlockByDefault = lib.mkOption {
    type = lib.types.bool;
    default = true;
    example = false;
    description = ''
      Whether NumLock is on when the session starts. Disable on laptops whose
      numeric keypad is embedded in the letter keys, where NumLock turns
      letters like U/I/O into digits.
    '';
  };

  config.wayland.windowManager.hyprland.settings = {
    config = {
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        numlock_by_default = config.omanix.hyprland.numlockByDefault;
      };
    };

    gesture = {
      _args = [
        (lib.generators.mkLuaInline ''{
          fingers = 3,
          direction = "horizontal",
          action = "workspace",
        }'')
      ];
    };
  };
}
