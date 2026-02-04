{ config, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        "layout.css.devPixelsPerPx" = "1.0";
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "widget.wayland.overscroll.enabled" = true;
        "browser.tabs.inTitlebar" = 1;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      userChrome = ''
        :root {
          --toolbar-bgcolor: ${config.omanix.activeTheme.colors.background} !important;
          --tab-selected-bgcolor: ${config.omanix.activeTheme.colors.background} !important;
          --omanix-accent: ${config.omanix.activeTheme.colors.accent};
          --omanix-fg: ${config.omanix.activeTheme.colors.foreground};
          --omanix-bg: ${config.omanix.activeTheme.colors.background};
        }

        /* Toolbar/tab bar background */
        #navigator-toolbox {
          background-color: var(--omanix-bg) !important;
        }

        /* All tabs - slightly dimmed */
        .tabbrowser-tab {
          opacity: 0.6 !important;
        }

        /* Selected/active tab - full opacity + accent underline */
        .tabbrowser-tab[selected="true"] {
          opacity: 1 !important;
        }

        /* Add accent color indicator to selected tab */
        .tabbrowser-tab[selected="true"] .tab-background {
          border-bottom: 2px solid var(--omanix-accent) !important;
        }

        /* Alternative: Add a subtle background tint to selected tab */
        .tabbrowser-tab[selected="true"] .tab-background {
          background: linear-gradient(
            to top,
            color-mix(in srgb, var(--omanix-accent) 15%, transparent),
            transparent 50%
          ) !important;
          border-bottom: 2px solid var(--omanix-accent) !important;
        }

        /* Make tab text brighter on selected tab */
        .tabbrowser-tab[selected="true"] .tab-label {
          color: var(--omanix-fg) !important;
          font-weight: 500 !important;
        }

        /* Hover state for non-selected tabs */
        .tabbrowser-tab:not([selected="true"]):hover {
          opacity: 0.85 !important;
        }
      '';
    };
  };
}
