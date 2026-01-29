{
  config,
  pkgs,
  lib,
  inputs,
  omarchyLib,
  ...
}:

let
  elephantPkg = inputs.elephant.packages.${pkgs.system}.default;
  availableThemes = builtins.attrNames omarchyLib.themes;
  
  # NixOS puts .desktop files in these locations
  # The key is XDG_DATA_DIRS must include all paths where apps are installed
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
  # Install elephant package
  home.packages = [ elephantPkg ];

  xdg.configFile = {
    # Desktop applications provider - key settings for NixOS
    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = false
      history = true
    '';

    # Main elephant configuration with all providers
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

    "elephant/runner.toml".text = ''
      # Runner provider - executes commands from PATH
    '';

    "elephant/files.toml".text = ''
      min_score = 50
      # Limit file watching to reasonable dirs on NixOS
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

    # Omarchy themes menu
    "elephant/menus/omarchy_themes.lua".text = ''
      Name = "omarchythemes"
      NamePretty = "Omarchy Themes"

      function GetEntries()
        local entries = {}
        local themes = { "${lib.concatStringsSep "\", \"" availableThemes}" }
        
        for _, name in ipairs(themes) do
          table.insert(entries, {
            Text = name:gsub("-", " "):gsub("^%l", string.upper),
            Subtext = "NixOS: Change 'omarchy.theme' in your flake to apply.",
            Actions = {
              activate = "notify-send 'NixOS Theme' 'Edit your flake.nix to change theme to " .. name .. "'",
            },
          })
        end
        return entries
      end
    '';
  };

  # CRITICAL: Elephant needs XDG_DATA_DIRS to find .desktop files
  # This is set system-wide for the session
  home.sessionVariables = {
    # Ensure XDG_DATA_DIRS includes NixOS profile paths
    XDG_DATA_DIRS = lib.mkDefault "${nixosDataDirs}";
  };

  # Systemd service with proper environment
  systemd.user.services.elephant = lib.mkForce {
    Unit = {
      Description = "Elephant Data Provider for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      # CRITICAL: Pass through the session's XDG_DATA_DIRS
      # This allows elephant to find .desktop files in NixOS paths
      Environment = [
        "XDG_DATA_DIRS=%h/.nix-profile/share:/etc/profiles/per-user/%u/share:/run/current-system/sw/share:%h/.local/share:/usr/local/share:/usr/share"
        "PATH=/run/current-system/sw/bin:%h/.nix-profile/bin"
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
