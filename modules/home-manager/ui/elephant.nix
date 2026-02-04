{
  pkgs,
  lib,
  inputs,
  omanixLib,
  ...
}:

let
  elephantPkg = inputs.elephant.packages.${pkgs.system}.default;
  availableThemes = builtins.attrNames omanixLib.themes;

  nixosDataDirs = lib.concatStringsSep ":" [
    "\${HOME}/.nix-profile/share"
    "/etc/profiles/per-user/\${USER}/share"
    "/run/current-system/sw/share"
    "\${HOME}/.local/share"
    "/usr/local/share"
    "/usr/share"
  ];
in
{
  home.packages = [ elephantPkg ];

  xdg.configFile = {
    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = true
      history = true
    '';

    "elephant/elephant.toml".text = ''
      [providers]
      desktopapplications = "desktopapplications"
      websearch = "websearch"
      files = "files"
      symbols = "symbols"
      clipboard = "clipboard"
      menus = "menus"
      calc = "calc"
      runner = "runner"
      providerlist = "providerlist"
    '';

    "elephant/calc.toml".text = ''
      async = false
    '';

    "elephant/runner.toml".text = "";

    "elephant/files.toml".text = ''
      min_score = 50
      dirs = [
        "~/Documents",
        "~/Downloads",
        "~/projects",
        "~/.config"
      ]
    '';

    "elephant/clipboard.toml".text = ''
      max_items = 100
    '';

    "elephant/websearch.toml".text = ''
      [[engines]]
      name = "Google"
      url = "https://www.google.com/search?q=%s"
      prefix = "g"

      [[engines]]
      name = "DuckDuckGo"
      url = "https://duckduckgo.com/?q=%s"
      prefix = "d"

      [[engines]]
      name = "NixOS Packages"
      url = "https://search.nixos.org/packages?query=%s"
      prefix = "nix"
    '';

    "elephant/menus/omanix_themes.lua".text = ''
      Name = "omanixthemes"
      NamePretty = "Omarchy Themes"

      function GetEntries()
        local entries = {}
        local themes = { "${lib.concatStringsSep "\", \"" availableThemes}" }
        
        for _, name in ipairs(themes) do
          table.insert(entries, {
            Text = name:gsub("-", " "):gsub("^%l", string.upper),
            Subtext = "NixOS: Change 'omanix.theme' in your flake to apply.",
            Actions = {
              activate = "notify-send 'NixOS Theme' 'Edit your flake.nix to change theme to " .. name .. "'",
            },
          })
        end
        return entries
      end
    '';
  };

  home.sessionVariables = {
    XDG_DATA_DIRS = lib.mkDefault "${nixosDataDirs}";
  };

  systemd.user.services.elephant = lib.mkForce {
    Unit = {
      Description = "Elephant Data Provider for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Environment = [
        "XDG_DATA_DIRS=%h/.nix-profile/share:/etc/profiles/per-user/%u/share:/run/current-system/sw/share:%h/.local/share:/usr/local/share:/usr/share"
        "PATH=/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:%h/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin"
      ];
      ExecStart = "${elephantPkg}/bin/elephant --config %h/.config/elephant";
      Restart = "always";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
