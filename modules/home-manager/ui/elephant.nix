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
  
  # NixOS-specific paths for desktop files
  nixosDataDirs = lib.concatStringsSep ":" [
    "/run/current-system/sw/share"
    "\${HOME}/.nix-profile/share"
    "\${HOME}/.local/share"
    "/etc/profiles/per-user/\${USER}/share"
  ];
in
{
  # Install the elephant package
  home.packages = [ elephantPkg ];

  xdg.configFile = {
    # Desktop applications provider config
    # Note: On NixOS, XDG_DATA_DIRS is the key - the provider uses that to find .desktop files
    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = false
      history = true
    '';

    # Main elephant configuration
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
      # Runner provider config
    '';

    "elephant/files.toml".text = ''
      min_score = 50
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

  # The critical fix: elephant needs proper XDG_DATA_DIRS to find .desktop files
  # This systemd service inherits the user session environment which should have XDG_DATA_DIRS set
  systemd.user.services.elephant = lib.mkForce {
    Unit = {
      Description = "Elephant Data Provider for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      # CRITICAL: Set XDG_DATA_DIRS so elephant can find .desktop files on NixOS
      # Also inherit the user's environment to get other important vars
      Environment = [
        "XDG_DATA_DIRS=${nixosDataDirs}:/usr/local/share:/usr/share"
        "PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.bash ]}:/run/current-system/sw/bin"
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
