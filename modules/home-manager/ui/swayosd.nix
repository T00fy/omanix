{ config, pkgs, ... }:
let
  theme = config.omanix.activeTheme;
in
{
  # SwayOSD package
  home.packages = [ pkgs.swayosd ];

  # Themed CSS for SwayOSD
  xdg.configFile."swayosd/style.css".text = ''
    window {
      background: alpha(${theme.colors.background}, 0.9);
      border-radius: 12px;
      border: 2px solid ${theme.colors.accent};
      padding: 12px;
    }

    #container {
      margin: 12px;
    }

    image, label {
      color: ${theme.colors.foreground};
    }

    progressbar {
      min-height: 8px;
      border-radius: 4px;
      background: alpha(${theme.colors.color8}, 0.5);
    }

    progressbar:disabled {
      background: alpha(${theme.colors.color1}, 0.3);
    }

    progressbar progress {
      min-height: 8px;
      border-radius: 4px;
      background: ${theme.colors.accent};
    }

    progressbar progress:disabled {
      background: ${theme.colors.color1};
    }
  '';
}
