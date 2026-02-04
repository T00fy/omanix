{ config, pkgs, ... }:
let
  theme = config.omanix.activeTheme;

  batThemeFile = pkgs.fetchurl {
    inherit (theme.bat) url;
    inherit (theme.bat) sha256;
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

  programs.zsh.shellAliases = {
    cat = "bat -pp";
  };
}
