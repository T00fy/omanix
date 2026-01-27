{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "us";
      kb_options = "compose:caps";
      
      follow_mouse = 1;
      
      touchpad = {
        natural_scroll = false;
        scroll_factor = 0.4;
      };
    };

    gestures = {
      workspace_swipe = true;
    };
  };
}
