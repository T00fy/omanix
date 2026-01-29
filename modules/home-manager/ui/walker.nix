{ config, pkgs, inputs, ... }:
let
  theme = config.omarchy.activeTheme;
  
  # CSS Content
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

    .current { font-style: italic; }

    .keybind-hints {
      background: @background;
      padding: 10px;
      margin-top: 10px;
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
      theme = "omarchy-default"; # This tells Walker to look in themes/omarchy-default
      hide_action_hints = true;
      
      width = 644;
      maxheight = 300;
      minheight = 300;

      providers = {
        max_results = 256;
        default = [ "desktopapplications" "websearch" ];
      };

      prefixes = [
        { prefix = "/"; provider = "providerlist"; }
        { prefix = "."; provider = "files"; }
        { prefix = ":"; provider = "symbols"; }
        { prefix = "="; provider = "calc"; }
        { prefix = "@"; provider = "websearch"; }
        { prefix = "$"; provider = "clipboard"; }
      ];

      emergencies = [
        {
          text = "Restart Walker";
          command = "omarchy-restart-walker";
        }
      ];
    };
  };

  # Manually write the theme files
  xdg.configFile = {
    "walker/themes/omarchy-default/style.css".text = styleCss;
    # Ensure layout.xml matches asset
    "walker/themes/omarchy-default/layout.xml".source = ../../../assets/branding/walker-layout.xml;
  };
}
