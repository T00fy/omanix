{
  pkgs,
  inputs,
  config,
  ...
}:
let
  # Determine fallback based on what is enabled in the user config
  defaultBrowser = if config.programs.firefox.enable then "firefox.desktop" else "chromium.desktop"; # TODO need to add chromium as an option

  # Override the generic package with specific config for this user
  omanixScripts = pkgs.omanix-scripts.override {
    browserFallback = defaultBrowser;
    walker = inputs.walker.packages.${pkgs.system}.default;
  };

  smartDelete = pkgs.writeShellScriptBin "omanix-smart-delete" ''
    # 1. Get info about the currently active window
    ACTIVE=$(${pkgs.hyprland}/bin/hyprctl activewindow -j)
    CLASS=$(echo "$ACTIVE" | ${pkgs.jq}/bin/jq -r ".class")
    ADDRESS=$(echo "$ACTIVE" | ${pkgs.jq}/bin/jq -r ".address")

    # Target specific window by address to ensure focus doesn't drift
    TARGET="address:$ADDRESS"

    # 2. Check if it's a terminal
    if [[ "$CLASS" =~ "ghostty" || "$CLASS" =~ "kitty" || "$CLASS" =~ "Alacritty" || "$CLASS" =~ "neovide" ]]; then
      # Terminal: Send Ctrl + U (Standard Unix "Kill Line Backward")
      ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "CTRL, U, $TARGET"
    else
      # Browsers/GUIs: Send Shift + Home (Select to start) then Backspace (Delete selection)
      ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut "SHIFT, Home, $TARGET"
      ${pkgs.hyprland}/bin/hyprctl dispatch sendshortcut ", Backspace, $TARGET"
    fi
  '';

in
{
  home.packages = [
    omanixScripts
    smartDelete

    pkgs.jq
    pkgs.procps

    pkgs.nautilus
    pkgs.chromium
    pkgs.firefox
  ];
}
