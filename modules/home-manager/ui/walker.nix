{ config, pkgs, lib, inputs, ... }:
let
  theme = config.omarchy.activeTheme;
  elephantPkg = inputs.elephant.packages.${pkgs.system}.default;
  
  styleCss = ''
    @define-color selected-text ${theme.colors.accent};
    @define-color text ${theme.colors.foreground};
    @define-color base ${theme.colors.background};
    @define-color border ${theme.colors.foreground};
    @define-color background ${theme.colors.background};
    @define-color foreground ${theme.colors.foreground};

    * { all: unset; }

    * {
      font-family: '${config.omarchy.font}';
      font-size: 18px;
      color: @text;
    }

    scrollbar { opacity: 0; }

    .normal-icons { -gtk-icon-size: 16px; }
    .large-icons { -gtk-icon-size: 32px; }

    .box-wrapper {
      background: alpha(@base, 0.95);
      padding: 20px;
      border: 2px solid @border;
    }

    .search-container {
      background: @base;
      padding: 10px;
    }

    .input placeholder { opacity: 0.5; }

    .input:focus, .input:active {
      box-shadow: none;
      outline: none;
    }

    child:selected .item-box * {
      color: @selected-text;
    }

    .item-box { padding-left: 14px; }

    .item-text-box {
      all: unset;
      padding: 14px 0;
    }

    .item-subtext {
      font-size: 0px;
      min-height: 0px;
      margin: 0px;
      padding: 0px;
    }

    .item-image {
      margin-right: 14px;
      -gtk-icon-transform: scale(0.9);
    }
    
    /* Support for nerd font icons in menus */
    .item-image-text {
      font-family: '${config.omarchy.font}';
      font-size: 18px;
      margin-right: 14px;
    }

    .current { font-style: italic; }

    .keybind-hints {
      background: @background;
      padding: 10px;
      margin-top: 10px;
    }
    
    .keybinds { 
      opacity: 0;
      min-height: 0;
      min-width: 0;
    }
  '';
in
{
  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      force_keyboard_focus = true;
      selection_wrap = true;
      theme = "omarchy-default";
      hide_action_hints = true;
      close_when_open = true;
      click_to_close = true;
      
      width = 644;
      maxheight = 300;
      minheight = 300;

      keybinds.quick_activate = [];

      providers = {
        max_results = 256;
        default = [ "desktopapplications" "websearch" ];
        empty = [ "desktopapplications" ];
        
        # Sets allow launching Walker with different provider configurations
        # The "omarchy" set includes ALL menu files for universal search
        sets.omarchy = {
          default = [
            "menus:omarchy"
            "menus:omarchylearn"
            "menus:omarchytrigger"
            "menus:omarchyscreenshot"
            "menus:omarchyscreenrecord"
            "menus:omarchyshare"
            "menus:omarchysetup"
            "menus:omarchysystem"
          ];
          empty = [ "menus:omarchy" ];
        };
      };

      prefixes = [
        { prefix = "/"; provider = "providerlist"; }
        { prefix = "."; provider = "files"; }
        { prefix = ":"; provider = "symbols"; }
        { prefix = "="; provider = "calc"; }
        { prefix = "@"; provider = "websearch"; }
        { prefix = "$"; provider = "clipboard"; }
        { prefix = ">"; provider = "runner"; }
      ];

      placeholders = {
        "default" = {
          input = "Launch...";
          list = "No Results";
        };
        "desktopapplications" = {
          input = "Launch...";
          list = "No Apps Found";
        };
        "files" = {
          input = "Find files...";
          list = "No files found";
        };
        "symbols" = {
          input = "Find symbol...";
          list = "No symbols";
        };
        "clipboard" = {
          input = "Clipboard...";
          list = "Clipboard empty";
        };
        "menus:omarchy" = {
          input = "Menu...";
          list = "No Results";
        };
      };

      emergencies = [
        {
          text = "Restart Walker";
          command = "omarchy-restart-walker";
        }
      ];
    };
  };

  systemd.user.services.walker = lib.mkIf config.programs.walker.runAsService {
    Service.Environment = lib.mkForce [
      "PATH=${elephantPkg}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:${config.home.homeDirectory}/.nix-profile/bin"
      "XDG_DATA_DIRS=${config.home.homeDirectory}/.nix-profile/share:/etc/profiles/per-user/${config.home.username}/share:/run/current-system/sw/share:${config.home.homeDirectory}/.local/share:/usr/local/share:/usr/share"
    ];
  };

  xdg.configFile = {
    "walker/themes/omarchy-default/style.css".text = styleCss;
    "walker/themes/omarchy-default/layout.xml".source = ../../../assets/branding/walker-layout.xml;
  };
}
