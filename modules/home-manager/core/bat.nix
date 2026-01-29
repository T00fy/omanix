{ config, pkgs, lib, ... }:
let
  theme = config.omanix.activeTheme;
  
  # Fetch the theme file from the URL defined in the theme
  batThemeFile = pkgs.fetchurl {
    url = theme.bat.url;
    sha256 = theme.bat.sha256;
  };
in
{
  programs.bat = {
    enable = true;
    
    config = {
      theme = theme.bat.name;
    };
    
    themes = {
      ${theme.bat.name} = {
        src = batThemeFile;
      };
    };
  };

  # Shell alias for cat replacement (plain output, no pager)
  programs.zsh.shellAliases = {
    cat = "bat -pp";
  };
}
