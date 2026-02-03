{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omanix;
  theme = cfg.activeTheme;
  colors = theme.colors;

  defaultFont = "JetBrainsMono Nerd Font";

  wallpaperFilename =
    "omanix-background"
    + (lib.last (lib.splitString "." (builtins.baseNameOf (toString theme.assets.wallpaper))));

  # Build a custom SDDM theme package with our wallpaper included
  omanixSddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "omanix-sddm-theme";
    version = "1.0.0";

    # Use SilentSDDM as the base
    src = pkgs.fetchFromGitHub {
      owner = "uiriansan";
      repo = "SilentSDDM";
      rev = "v1.4.2";
      hash = "sha256-WeoJBj/PhqFCCJEIycTipqPbKm5BpQT2uzFTYcYZ30I=";
    };

    dontWrapQtApps = true;

    propagatedBuildInputs = with pkgs.kdePackages; [
      qtsvg
      qtmultimedia
      qtvirtualkeyboard
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/sddm/themes/omanix

      # Copy all theme files
      cp -r Main.qml metadata.desktop qmldir components configs fonts icons $out/share/sddm/themes/omanix/

      # Create backgrounds directory and copy our wallpaper
      mkdir -p $out/share/sddm/themes/omanix/backgrounds
      cp ${theme.assets.wallpaper} $out/share/sddm/themes/omanix/backgrounds/${wallpaperFilename}

      # Update metadata to use our config
      cat > $out/share/sddm/themes/omanix/metadata.desktop << EOF
      [SddmGreeterTheme]
      Name=Omanix
      Description=Omanix SDDM Theme (based on SilentSDDM)
      Author=Omanix
      Website=https://github.com/uiriansan/SilentSDDM
      License=GPL-3.0
      Type=sddm-theme
      Version=1.0.0
      ConfigFile=configs/omanix.conf
      EOF

      runHook postInstall
    '';

    postInstall = ''
      # Generate the omanix config file with our theme colors
      cat > $out/share/sddm/themes/omanix/configs/omanix.conf << 'OMANIX_CONFIG'
      [General]
      scale=1.0
      enable-animations=true
      background-fill-mode=fill

      [LockScreen]
      display=${if cfg.login.lockScreen.enable then "true" else "false"}
      background=${wallpaperFilename}
      blur=${toString cfg.login.lockScreen.blur}
      brightness=${toString cfg.login.lockScreen.brightness}
      saturation=0.0
      padding-top=50
      padding-bottom=50

      [LockScreen.Clock]
      display=true
      position=center
      align=center
      format=hh:mm
      font-family=${cfg.login.font}
      font-size=90
      font-weight=700
      color=${colors.foreground}

      [LockScreen.Date]
      display=true
      format=dddd, MMMM dd, yyyy
      font-family=${cfg.login.font}
      font-size=16
      font-weight=400
      color=${colors.foreground}
      margin-top=10

      [LockScreen.Message]
      display=true
      position=bottom-center
      align=center
      text=Press any key to continue
      font-family=${cfg.login.font}
      font-size=14
      font-weight=400
      color=${colors.foreground}
      display-icon=true
      icon-size=18
      paint-icon=true

      [LoginScreen]
      background=${wallpaperFilename}
      blur=${toString cfg.login.loginScreen.blur}
      brightness=${toString cfg.login.loginScreen.brightness}
      saturation=0.0

      [LoginScreen.LoginArea]
      position=center
      margin=-1

      [LoginScreen.LoginArea.Avatar]
      shape=circle
      active-size=100
      inactive-size=70
      inactive-opacity=0.4
      active-border-size=3
      inactive-border-size=0
      active-border-color=${colors.accent}
      inactive-border-color=${colors.foreground}

      [LoginScreen.LoginArea.Username]
      font-family=${cfg.login.font}
      font-size=18
      font-weight=600
      color=${colors.foreground}
      margin=15

      [LoginScreen.LoginArea.PasswordInput]
      width=280
      height=40
      display-icon=true
      font-family=${cfg.login.font}
      font-size=14
      icon-size=18
      content-color=${colors.foreground}
      background-color=${colors.background}
      background-opacity=0.7
      border-size=2
      border-color=${colors.accent}
      border-radius-left=8
      border-radius-right=0
      margin-top=20

      [LoginScreen.LoginArea.LoginButton]
      background-color=${colors.accent}
      background-opacity=0.9
      active-background-color=${colors.accent}
      active-background-opacity=1.0
      icon-size=20
      content-color=${colors.background}
      active-content-color=${colors.background}
      border-size=0
      border-radius-left=0
      border-radius-right=8
      margin-left=0
      font-family=${cfg.login.font}
      font-size=14
      font-weight=600

      [LoginScreen.LoginArea.Spinner]
      display-text=true
      text=Logging in...
      font-family=${cfg.login.font}
      font-weight=500
      font-size=14
      icon-size=28
      color=${colors.foreground}

      [LoginScreen.LoginArea.WarningMessage]
      font-family=${cfg.login.font}
      font-size=12
      font-weight=400
      normal-color=${colors.foreground}
      warning-color=${colors.color3}
      error-color=${colors.color1}
      margin-top=15

      [LoginScreen.MenuArea.Buttons]
      margin-top=20
      margin-right=20
      margin-bottom=20
      margin-left=20
      size=36
      border-radius=8
      spacing=10
      font-family=${cfg.login.font}

      [LoginScreen.MenuArea.Popups]
      max-height=250
      item-height=36
      item-spacing=2
      padding=8
      display-scrollbar=true
      margin=8
      background-color=${colors.background}
      background-opacity=0.95
      active-option-background-color=${colors.accent}
      active-option-background-opacity=0.3
      content-color=${colors.foreground}
      active-content-color=${colors.accent}
      font-family=${cfg.login.font}
      border-size=1
      border-color=${colors.color8}
      font-size=13
      icon-size=18

      [LoginScreen.MenuArea.Session]
      display=true
      position=bottom-left
      index=0
      popup-direction=up
      popup-align=start
      display-session-name=true
      button-width=-1
      popup-width=220
      background-color=${colors.background}
      background-opacity=0.6
      active-background-opacity=0.8
      content-color=${colors.foreground}
      active-content-color=${colors.accent}
      border-size=1
      font-size=12
      icon-size=18

      [LoginScreen.MenuArea.Layout]
      display=true
      position=bottom-right
      index=0
      popup-direction=up
      popup-align=end
      popup-width=200
      display-layout-name=true
      background-color=${colors.background}
      background-opacity=0.6
      active-background-opacity=0.8
      content-color=${colors.foreground}
      active-content-color=${colors.accent}
      border-size=1
      font-size=12
      icon-size=18

      [LoginScreen.MenuArea.Keyboard]
      display=true
      position=bottom-right
      index=1
      background-color=${colors.background}
      background-opacity=0.6
      active-background-opacity=0.8
      content-color=${colors.foreground}
      active-content-color=${colors.accent}
      border-size=1
      icon-size=18

      [LoginScreen.MenuArea.Power]
      display=true
      position=bottom-right
      index=2
      popup-direction=up
      popup-align=end
      popup-width=120
      background-color=${colors.background}
      background-opacity=0.6
      active-background-opacity=0.8
      content-color=${colors.foreground}
      active-content-color=${colors.color1}
      border-size=1
      icon-size=18

      [LoginScreen.VirtualKeyboard]
      scale=1.0
      position=bottom
      start-hidden=true
      background-color=${colors.background}
      background-opacity=0.95
      key-content-color=${colors.foreground}
      key-color=${colors.color0}
      key-opacity=0.8
      key-active-background-color=${colors.accent}
      key-active-opacity=0.9
      selection-background-color=${colors.accent}
      selection-content-color=${colors.background}
      primary-color=${colors.accent}
      border-size=1
      border-color=${colors.color8}

      [Tooltips]
      enable=true
      font-family=${cfg.login.font}
      font-size=12
      content-color=${colors.foreground}
      background-color=${colors.background}
      background-opacity=0.95
      border-radius=6
      OMANIX_CONFIG
    '';

    meta = {
      description = "Omanix SDDM Theme based on SilentSDDM";
      license = lib.licenses.gpl3;
      platforms = lib.platforms.linux;
    };
  };
in
{
  options.omanix.login = {
    enable = lib.mkEnableOption "Omanix login screen (SDDM)" // {
      default = true;
    };

    font = lib.mkOption {
      type = lib.types.str;
      default = defaultFont;
      description = "Font family for the login screen.";
    };

    lockScreen = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to show the lock screen before login.";
      };

      blur = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Blur amount for lock screen background (0 = no blur).";
      };

      brightness = lib.mkOption {
        type = lib.types.float;
        default = (-0.2);
        description = "Brightness adjustment for lock screen (-1.0 to 1.0).";
      };
    };

    loginScreen = {
      blur = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "Blur amount for login screen background (0 = no blur).";
      };

      brightness = lib.mkOption {
        type = lib.types.float;
        default = (-0.3);
        description = "Brightness adjustment for login screen (-1.0 to 1.0).";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.login.enable) {
    # Enable Qt for SDDM
    qt.enable = true;

    # Configure SDDM directly (not using the silentSDDM module)
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      theme = "omanix";
      extraPackages = omanixSddmTheme.propagatedBuildInputs;
      settings = {
        General = {
          InputMethod = "qtvirtualkeyboard";
          GreeterEnvironment = "QML2_IMPORT_PATH=${omanixSddmTheme}/share/sddm/themes/omanix/components/,QT_IM_MODULE=qtvirtualkeyboard";
        };
      };
      wayland.enable = true;
    };

    # Add our theme to system packages
    environment.systemPackages = [ omanixSddmTheme ];
  };
}
