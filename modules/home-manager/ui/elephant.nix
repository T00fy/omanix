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
in
{
  xdg.configFile = {
    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = true
      history = false
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
    '';

    "elephant/calc.toml".text = ''
      async = false
    '';
    "elephant/menus/omarchy_themes.lua".text = ''
      Name = "omarchythemes"
      NamePretty = "Omarchy Themes"

      function GetEntries()
        local entries = {}
        -- Generate entries from our Nix theme list
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

  systemd.user.services.elephant = lib.mkForce {
    Unit = {
      Description = "Elephant Data Provider for Walker";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${elephantPkg}/bin/elephant --config %h/.config/elephant";
      Restart = lib.mkForce "always";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
