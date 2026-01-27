{ config, pkgs, ... }:
let
  theme = config.omarchy.activeTheme;
in
{
  home.packages = with pkgs; [
    yaru-theme
    gnome-themes-extra
    adwaita-icon-theme
    # Ensure the font we are configuring is actually available
    liberation_ttf
  ];

  gtk = {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = theme.meta.icon_theme;
      package = pkgs.yaru-theme;
    };

    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };

    # Explicitly match Omarchy's fonts.conf intent
    font = {
      name = "Liberation Sans";
      size = 11;
      package = pkgs.liberation_ttf;
    };
  };
}
