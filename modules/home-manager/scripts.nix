{ pkgs, ... }:
let
  # omarchy-cmd-screenshot
  screenshot = pkgs.writeShellScriptBin "omarchy-cmd-screenshot" ''
    MODE=''${1:-smart}
    DEST=''${2:-file}
    DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$DIR"
    FILE="$DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

    if [ "$MODE" == "smart" ] || [ "$MODE" == "region" ]; then
      SELECTION=$(${pkgs.slurp}/bin/slurp)
    elif [ "$MODE" == "output" ]; then
      SELECTION=$(${pkgs.slurp}/bin/slurp -o)
    fi

    if [ -z "$SELECTION" ]; then exit 0; fi

    if [ "$DEST" == "clipboard" ]; then
      ${pkgs.grim}/bin/grim -g "$SELECTION" - | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send "Screenshot copied to clipboard"
    else
      ${pkgs.grim}/bin/grim -g "$SELECTION" "$FILE"
      ${pkgs.wl-clipboard}/bin/wl-copy < "$FILE"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "Saved to $FILE"
    fi
  '';

  launchBrowser = pkgs.writeShellScriptBin "omarchy-launch-browser" ''
    BROWSER="chromium"
    if [[ "$1" == "--private" ]]; then
      exec $BROWSER --incognito
    else
      exec $BROWSER
    fi
  '';

in
{
  home.packages = [
    screenshot
    launchBrowser
    
    pkgs.slurp
    pkgs.swayosd
    pkgs.grim
    pkgs.wl-clipboard
    pkgs.libnotify
    pkgs.playerctl
    pkgs.brightnessctl
    pkgs.wireplumber 
    pkgs.hyprpicker
    
    pkgs.wofi
    pkgs.pavucontrol
    pkgs.blueman
    pkgs.nautilus
    pkgs.chromium

    pkgs.firefox
  ];
}
