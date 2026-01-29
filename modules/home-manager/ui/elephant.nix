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
    # ═══════════════════════════════════════════════════════════════════
    # ELEPHANT CORE CONFIG
    # ═══════════════════════════════════════════════════════════════════

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

    "elephant/desktopapplications.toml".text = ''
      show_actions = false
      only_search_title = true
      history = true
    '';

    "elephant/calc.toml".text = ''
      async = false
    '';

    "elephant/runner.toml".text = '''';

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

    # ═══════════════════════════════════════════════════════════════════
    # OMARCHY MENU SYSTEM
    # ═══════════════════════════════════════════════════════════════════

    "elephant/menus/omarchy.toml".text = ''
      name = "omarchy"
      name_pretty = "Omarchy"
      search_name = true

      [[entries]]
      text = "Apps"
      icon = "󰀻"
      actions = { "launch" = "omarchy-launch-walker" }

      [[entries]]
      text = "Learn"
      icon = "󰧑"
      submenu = "omarchylearn"

      [[entries]]
      text = "Trigger"
      icon = "󱓞"
      submenu = "omarchytrigger"

      [[entries]]
      text = "Style"
      icon = "󰏘"
      actions = { "open" = "omarchy-show-style-help" }

      [[entries]]
      text = "Setup"
      icon = "󰒓"
      submenu = "omarchysetup"

      [[entries]]
      text = "System"
      icon = "󰍛"
      submenu = "omarchysystem"
    '';

    "elephant/menus/omarchylearn.toml".text = ''
      name = "omarchylearn"
      name_pretty = "Learn"
      search_name = true

      [[entries]]
      text = "Keybindings"
      icon = "󰌌"
      actions = { "open" = "omarchy-menu-keybindings" }

      [[entries]]
      text = "Hyprland Wiki"
      icon = "󰖟"
      actions = { "open" = "xdg-open https://wiki.hyprland.org" }

      [[entries]]
      text = "NixOS Wiki"
      icon = "󱄅"
      actions = { "open" = "xdg-open https://wiki.nixos.org" }

      [[entries]]
      text = "Neovim Docs"
      icon = "󰊠"
      actions = { "open" = "xdg-open https://neovim.io/doc/" }

      [[entries]]
      text = "Bash Manual"
      icon = "󱆃"
      actions = { "open" = "xdg-open https://www.gnu.org/software/bash/manual/" }
    '';

    "elephant/menus/omarchytrigger.toml".text = ''
      name = "omarchytrigger"
      name_pretty = "Trigger"
      search_name = true

      [[entries]]
      text = "Screenshot"
      icon = "󰹑"
      submenu = "omarchyscreenshot"

      [[entries]]
      text = "Screenrecord"
      icon = "󰻃"
      submenu = "omarchyscreenrecord"

      [[entries]]
      text = "Share"
      icon = "󰤲"
      submenu = "omarchyshare"

      [[entries]]
      text = "Color Picker"
      icon = "󰃉"
      actions = { "pick" = "hyprpicker -a" }
    '';

    "elephant/menus/omarchyscreenshot.toml".text = ''
      name = "omarchyscreenshot"
      name_pretty = "Screenshot"
      search_name = true

      [[entries]]
      text = "Snap with Editing"
      icon = "󰏫"
      actions = { "snap" = "omarchy-cmd-screenshot smart" }

      [[entries]]
      text = "Straight to Clipboard"
      icon = "󰅍"
      actions = { "snap" = "omarchy-cmd-screenshot smart clipboard" }
    '';

    "elephant/menus/omarchyscreenrecord.toml".text = ''
      name = "omarchyscreenrecord"
      name_pretty = "Screenrecord"
      search_name = true

      [[entries]]
      text = "Full Screen"
      icon = "󰍹"
      actions = { "record" = "notify-send 'Screen Recording' 'Full screen recording not yet implemented'" }

      [[entries]]
      text = "Region"
      icon = "󰆞"
      actions = { "record" = "notify-send 'Screen Recording' 'Region recording not yet implemented'" }

      [[entries]]
      text = "Stop Recording"
      icon = "󰓛"
      actions = { "stop" = "pkill -SIGINT wf-recorder || pkill -SIGINT wl-screenrec" }
    '';

    "elephant/menus/omarchyshare.toml".text = ''
      name = "omarchyshare"
      name_pretty = "Share"
      search_name = true

      [[entries]]
      text = "LocalSend"
      icon = "󰷛"
      actions = { "open" = "localsend_app" }
    '';

    "elephant/menus/omarchysetup.toml".text = ''
      name = "omarchysetup"
      name_pretty = "Setup"
      search_name = true

      [[entries]]
      text = "Audio"
      icon = "󰕾"
      actions = { "open" = "omarchy-launch-audio" }

      [[entries]]
      text = "Wifi"
      icon = "󰖩"
      actions = { "open" = "omarchy-launch-wifi" }

      [[entries]]
      text = "Bluetooth"
      icon = "󰂯"
      actions = { "open" = "omarchy-launch-bluetooth" }

      [[entries]]
      text = "Hyprland"
      icon = "󰋁"
      actions = { "help" = "omarchy-show-setup-help hyprland" }

      [[entries]]
      text = "Hypridle"
      icon = "󰒲"
      actions = { "help" = "omarchy-show-setup-help hypridle" }

      [[entries]]
      text = "Hyprlock"
      icon = "󰌾"
      actions = { "help" = "omarchy-show-setup-help hyprlock" }

      [[entries]]
      text = "Waybar"
      icon = "󰍜"
      actions = { "help" = "omarchy-show-setup-help waybar" }

      [[entries]]
      text = "Walker"
      icon = "󰌧"
      actions = { "help" = "omarchy-show-setup-help walker" }
    '';

    "elephant/menus/omarchysystem.toml".text = ''
      name = "omarchysystem"
      name_pretty = "System"
      search_name = true

      [[entries]]
      text = "Lock"
      icon = "󰌾"
      actions = { "lock" = "omarchy-lock-screen" }

      [[entries]]
      text = "Screensaver"
      icon = "󱄄"
      actions = { "open" = "notify-send 'Screensaver' 'Not yet implemented'" }

      [[entries]]
      text = "Suspend"
      icon = "󰒲"
      actions = { "suspend" = "systemctl suspend" }

      [[entries]]
      text = "Relaunch"
      icon = "󰜉"
      actions = { "relaunch" = "hyprctl dispatch exit" }

      [[entries]]
      text = "Restart"
      icon = "󰜉"
      actions = { "restart" = "omarchy-cmd-reboot" }

      [[entries]]
      text = "Shutdown"
      icon = "󰐥"
      actions = { "shutdown" = "omarchy-cmd-shutdown" }
    '';

    # Theme list menu (dynamic from Nix)
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
