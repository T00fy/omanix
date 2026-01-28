{ config, pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        # THE SCALING FIX:
        # -1.0 = Follow system DPI (This causes the giant UI when Hyprland is scaled)
        #  1.0 = 100% Scale (Matches the force-device-scale-factor=1 fix in Chromium)
        "layout.css.devPixelsPerPx" = "1.0";

        # Required for smooth scrolling/touch on Wayland
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.wayland.overscroll.enabled" = true;
        
        # Omarchy Aesthetic: Remove title bar to match the "clean" look
        "browser.tabs.inTitlebar" = 1;
        
        # Optional: Enable userChrome.css support (Omarchy uses this for theming)
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      # Optional: Copy Omarchy's visual style into Firefox
      # This colors the tab bar to match your Tokyo Night theme background
      userChrome = ''
        :root {
          --toolbar-bgcolor: ${config.omarchy.activeTheme.colors.background} !important;
          --tab-selected-bgcolor: ${config.omarchy.activeTheme.colors.background} !important;
        }
        #navigator-toolbox { background-color: var(--toolbar-bgcolor) !important; }
      '';
    };
  };
}
