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
  };
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;

  terminalCwd = pkgs.writeShellScriptBin "omanix-cmd-terminal-cwd" ''
    active_pid=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq '.pid')
    if [[ -n "$active_pid" && "$active_pid" != "null" ]]; then
      shell_pid=$(${pkgs.procps}/bin/pgrep -P "$active_pid" | head -n1)
      if [[ -n "$shell_pid" ]]; then
        readlink -e "/proc/$shell_pid/cwd" || echo "$HOME"
      else
        echo "$HOME"
      fi
    else
      echo "$HOME"
    fi
  '';

  launchWalker = pkgs.writeShellScriptBin "omanix-launch-walker" ''
    WALKER="${walkerPkg}/bin/walker"

    # Ensure elephant is running
    if ! pgrep -x elephant > /dev/null; then
      systemctl --user start elephant.service
      sleep 0.5
    fi

    # Ensure walker service is running
    if ! pgrep -f "walker --gapplication-service" > /dev/null; then
      systemctl --user start walker.service
      sleep 0.3
    fi

    # Launch walker with specific Omarchy dimensions
    exec "$WALKER" --width 644 --maxheight 300 --minheight 300 "$@"
  '';

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
    terminalCwd
    launchWalker
    smartDelete

    pkgs.jq
    pkgs.procps

    pkgs.nautilus
    pkgs.chromium
    pkgs.firefox
  ];
}
