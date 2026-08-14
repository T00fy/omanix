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

  # Declare a dark color-scheme preference. GTK apps read
  # gtk-application-prefer-dark-theme, but xdg-desktop-portal-gtk reports
  # org.freedesktop.appearance color-scheme from the dconf key below.
  # Firefox 153+ (and other portal-aware apps) trust that portal signal
  # rather than inferring dark from the "Adwaita-dark" theme name, so
  # without this they render light.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;

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
