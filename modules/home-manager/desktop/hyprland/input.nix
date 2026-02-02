{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "us";
      kb_options = "compose:caps, caps:escape_shifted_capslock";
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
