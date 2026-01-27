{ config, lib, omarchyLib, ... }:
let
  theme = config.omarchy.activeTheme;
  colors = omarchyLib.colors;
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = true;
        ignore_empty_input = true;
      };

      background = [{
        path = "${theme.assets.wallpaper}";
        blur_passes = 3;
        color = colors.hexToRgbaCss theme.colors.background;
      }];

      input-field = [{
        size = "650, 100";
        position = "0, 0";
        halign = "center";
        valign = "center";

        outline_thickness = 4;
        dots_size = 0.33;
        dots_spacing = 0.15;
        dots_center = true;

        outer_color = "rgb(${colors.stripHash theme.colors.foreground})";
        inner_color = colors.hexToRgbaCss theme.colors.background;
        font_color = "rgb(${colors.stripHash theme.colors.foreground})";
        fade_on_empty = false;
        
        placeholder_text = "Enter Password";
        
        check_color = "rgb(${colors.stripHash theme.colors.accent})";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
      }];

      label = [
        # Time
        {
          text = "$TIME";
          color = "rgb(${colors.stripHash theme.colors.foreground})";
          font_size = 120;
          font_family = config.omarchy.font;
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          text = "cmd[update:1000] echo \"$(date +'%A, %d %B')\"";
          color = "rgb(${colors.stripHash theme.colors.foreground})";
          font_size = 30;
          font_family = config.omarchy.font;
          position = "0, 50";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
