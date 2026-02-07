{ config, ... }:
let
  theme = config.omanix.activeTheme;
in
{
  services.mako = {
    enable = true;

    settings = {
      # ═══════════════════════════════════════════════════════════════════
      # GLOBAL SETTINGS (from Omarchy core.ini)
      # ═══════════════════════════════════════════════════════════════════
      anchor = "top-right";
      default-timeout = 5000;
      width = 420;
      outer-margin = 20;
      padding = "10,15";
      border-size = 2;
      max-icon-size = 32;
      font = "sans-serif 14px";

      # ═══════════════════════════════════════════════════════════════════
      # THEME COLORS (resolved from active theme)
      # ═══════════════════════════════════════════════════════════════════
      text-color = theme.colors.foreground;
      border-color = theme.colors.accent;
      background-color = theme.colors.background;

      # ═══════════════════════════════════════════════════════════════════
      # APPLICATION-SPECIFIC RULES
      # ═══════════════════════════════════════════════════════════════════

      # Hide Spotify notifications (prevents song-change spam)
      "app-name=Spotify" = {
        invisible = 1;
      };

      # Do Not Disturb mode - hide everything
      "mode=do-not-disturb" = {
        invisible = true;
      };

      # Allow system notifications (notify-send) to bypass DND
      "mode=do-not-disturb app-name=notify-send" = {
        invisible = false;
      };

      # Critical notifications persist until dismissed
      "urgency=critical" = {
        default-timeout = 0;
        layer = "overlay";
      };
    };
  };
}
