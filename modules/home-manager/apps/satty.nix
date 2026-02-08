{ config, ... }:
let
  theme = config.omanix.activeTheme;
in
{
  programs.satty = {
    enable = true;

    settings = {
      general = {
        # Windowed mode — region is already selected via slurp before Satty opens
        fullscreen = false;

        # Exit after save/copy action
        early-exit = true;

        # Clipboard integration
        copy-command = "wl-copy";

        # Save file after copying to clipboard
        save-after-copy = true;

        # Output path with timestamp (chrono format specifiers)
        output-filename = "~/Pictures/screenshot-%Y-%m-%d_%H-%M-%S.png";

        # Enter key: copy to clipboard (file save handled by save-after-copy)
        actions-on-enter = [ "save-to-clipboard" ];

        # Escape key: just exit without saving
        actions-on-escape = [ "exit" ];

        # Start with the pointer tool (non-destructive default)
        initial-tool = "pointer";

        # Rounded rectangle corners
        corner-roundness = 12;

        # Larger annotations for readability
        annotation-size-factor = 2;

        # Smooth brush strokes
        brush-smooth-history-size = 10;

        # Hide window decoration (Hyprland manages this)
        no-window-decoration = true;
      };

      font = {
        family = config.omanix.font;
        style = "Regular";
      };

      color-palette = {
        palette = [
          theme.colors.accent
          theme.colors.color1
          theme.colors.color2
          theme.colors.color3
          theme.colors.color4
          theme.colors.color5
          theme.colors.color6
        ];
      };
    };
  };
}
