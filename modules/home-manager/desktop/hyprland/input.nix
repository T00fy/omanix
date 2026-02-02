{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "us";
      follow_mouse = 1;

      # touchpad = {
      #   natural_scroll = false;
      #   scroll_factor = 0.4;
      # };
    };

    # New gesture syntax (replaces the old gestures block)
    gesture = [
      "3, horizontal, workspace"
    ];
  };
}
