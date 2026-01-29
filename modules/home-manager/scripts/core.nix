{ pkgs, inputs, ... }:
let
  # Get walker from flake input for consistent versioning
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;

  # 1. Launch or Focus (New Upstream Parity)
  launchOrFocus = pkgs.writeShellScriptBin "omarchy-launch-or-focus" ''
    if (($# == 0)); then
      echo "Usage: omarchy-launch-or-focus [window-pattern] [launch-command]"
      exit 1
    fi

    WINDOW_PATTERN="$1"
    LAUNCH_COMMAND="''${2:-"uwsm app -- $WINDOW_PATTERN"}"

    WINDOW_ADDRESS=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r --arg p "$WINDOW_PATTERN" '.[] | select((.class | test($p; "i")) or (.title | test($p; "i"))) | .address' | head -n1)

    if [[ -n $WINDOW_ADDRESS ]]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
    else
      eval exec setsid $LAUNCH_COMMAND
    fi
  '';

  # 2. Launch Browser
  launchBrowser = pkgs.writeShellScriptBin "omarchy-launch-browser" ''
    BROWSER=$(${pkgs.xdg-utils}/bin/xdg-settings get default-web-browser 2>/dev/null || echo "firefox.desktop")

    if [[ "$BROWSER" == *"firefox"* ]]; then
      EXEC="firefox"
      PRIVATE_FLAG="--private-window"
    elif [[ "$BROWSER" == *"chromium"* || "$BROWSER" == *"chrome"* || "$BROWSER" == *"brave"* ]]; then
      EXEC="chromium" 
      PRIVATE_FLAG="--incognito"
    else
      EXEC="firefox"
      PRIVATE_FLAG="--private-window"
    fi

    if [[ "$1" == "--private" ]]; then
      exec $EXEC $PRIVATE_FLAG "''${@:2}"
    else
      exec $EXEC "$@"
    fi
  '';

  # 3. Terminal CWD
  terminalCwd = pkgs.writeShellScriptBin "omarchy-cmd-terminal-cwd" ''
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

  # 4. Launch Walker - use explicit path
  launchWalker = pkgs.writeShellScriptBin "omarchy-launch-walker" ''
    WALKER="${walkerPkg}/bin/walker"

    # Ensure elephant (the data provider) is running
    if ! pgrep -x elephant > /dev/null; then
      systemctl --user start elephant.service
      # Give it a moment to start
      sleep 0.5
    fi

    # Ensure walker service is running
    if ! pgrep -f "walker --gapplication-service" > /dev/null; then
      systemctl --user start walker.service
      sleep 0.3
    fi

    # Launch with Omarchy dimensions
    exec "$WALKER" --width 644 --maxheight 300 --minheight 300 "$@"
  '';

in
{
  home.packages = [
    launchOrFocus
    launchBrowser
    terminalCwd
    launchWalker

    # Core Dependencies
    pkgs.jq
    pkgs.procps

    # Core Apps
    pkgs.nautilus
    pkgs.chromium
    pkgs.firefox
  ];
}
