{ config, lib, omarchyLib, ... }:
let
  theme = config.omarchy.activeTheme;
  colors = theme.colors;
in
{
  programs.ghostty = {
    enable = true;
    settings = {
      window-padding-x = 14;
      window-padding-y = 14;
      window-decoration = false;
      confirm-close-surface = false;
      resize-overlay = "never";
      gtk-toolbar-style = "flat";
      
      cursor-style = "block";
      cursor-style-blink = false;
      mouse-scroll-multiplier = 1.0;      
      font-family = config.omarchy.font;
      font-style = "Regular";
      font-size = 9;

      # Theme Injection
      background = colors.background;
      foreground = colors.foreground;
      cursor-color = colors.cursor;
      selection-background = colors.selection_background;
      selection-foreground = colors.selection_foreground;
      
      palette = [
        "0=${colors.color0}"
        "1=${colors.color1}"
        "2=${colors.color2}"
        "3=${colors.color3}"
        "4=${colors.color4}"
        "5=${colors.color5}"
        "6=${colors.color6}"
        "7=${colors.color7}"
        "8=${colors.color8}"
        "9=${colors.color9}"
        "10=${colors.color10}"
        "11=${colors.color11}"
        "12=${colors.color12}"
        "13=${colors.color13}"
        "14=${colors.color14}"
        "15=${colors.color15}"
      ];
    };
  };
}
