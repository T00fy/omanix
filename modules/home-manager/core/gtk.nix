{ config, pkgs, ... }:
let
  theme = config.omanix.activeTheme;
in
{
  home.packages = with pkgs; [
    yaru-theme
    gnome-themes-extra
    adwaita-icon-theme
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

    font = {
      name = "Liberation Sans";
      size = 11;
      package = pkgs.liberation_ttf;
    };
  };
}
