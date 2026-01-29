{ pkgs, ... }:
let
  # 1. Launch or Focus (New Upstream Parity)
  launchOrFocus = pkgs.writeShellScriptBin "omarchy-launch-or-focus" ''
    if (($# == 0)); then
      echo "Usage: omarchy-launch-or-focus [window-pattern] [launch-command]"
      exit 1
    fi

    WINDOW_PATTERN="$1"
    LAUNCH_COMMAND="''${2:-"uwsm app -- $WINDOW_PATTERN"}"
    
    # Check if window exists via Hyprland clients
    # We use 'grep -i' for case-insensitive matching on class or title
    WINDOW_ADDRESS=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r --arg p "$WINDOW_PATTERN" '.[] | select((.class | test($p; "i")) or (.title | test($p; "i"))) | .address' | head -n1)

    if [[ -n $WINDOW_ADDRESS ]]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
    else
      # Use eval to handle complex command strings with arguments
      eval exec setsid $LAUNCH_COMMAND
    fi
  '';

  # 2. Launch Browser (Enhanced Upstream Parity)
  # Detects browser and handles private flags correctly
  launchBrowser = pkgs.writeShellScriptBin "omarchy-launch-browser" ''
    # Detect default browser (fallback to firefox if not set)
    BROWSER=$(${pkgs.xdg-utils}/bin/xdg-settings get default-web-browser 2>/dev/null || echo "firefox.desktop")
    
    # Extract binary name logic
    if [[ "$BROWSER" == *"firefox"* ]]; then
      EXEC="firefox"
      PRIVATE_FLAG="--private-window"
    elif [[ "$BROWSER" == *"chromium"* || "$BROWSER" == *"chrome"* || "$BROWSER" == *"brave"* ]]; then
      EXEC="chromium" 
      PRIVATE_FLAG="--incognito"
    else
      # Default fallback
      EXEC="firefox"
      PRIVATE_FLAG="--private-window"
    fi

    if [[ "$1" == "--private" ]]; then
      exec $EXEC $PRIVATE_FLAG "''${@:2}"
    else
      exec $EXEC "$@"
    fi
  '';

  # 3. Terminal CWD (New Upstream Parity)
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
in
{
  home.packages = [
    launchOrFocus
    launchBrowser
    terminalCwd
    
    # Core Dependencies
    pkgs.jq
    pkgs.procps # for pgrep
    
    # Core Apps (Moved from scripts.nix)
    pkgs.nautilus
    pkgs.chromium
    pkgs.firefox
  ];
}
