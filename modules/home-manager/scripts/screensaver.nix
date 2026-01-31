{ pkgs, config, ... }:
let
  tte = pkgs.python312Packages.terminaltexteffects;
  logoFile = ../../../assets/branding/logo.txt;

  # The effect runner (runs inside the terminal)
  # This script should exit cleanly when it receives any signal
  screensaverEffect = pkgs.writeShellScriptBin "omanix-screensaver-effect" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.ncurses}/bin:$PATH"

    # Track child PID
    TTE_PID=""

    # Cleanup on exit - just restore terminal state
    cleanup() {
      # Kill TTE if running
      [[ -n "$TTE_PID" ]] && kill "$TTE_PID" 2>/dev/null
      
      # Disable mouse tracking
      printf '\033[?1003l' 2>/dev/null || true
      # Restore cursor
      tput cnorm 2>/dev/null || true
      printf '\033[?25h' 2>/dev/null || true
      clear 2>/dev/null || true
      exit 0
    }
    
    # Trap all exit signals
    trap cleanup EXIT INT TERM HUP QUIT

    # Force pure black background (OLED black)
    printf '\033]11;rgb:00/00/00\007'

    # Hide the terminal cursor completely
    tput civis
    printf '\033[?25l'

    # Enable mouse tracking so we can detect mouse movement
    printf '\033[?1003h'

    # Available effects
    EFFECTS=(
      beams binarypath blackhole bouncyballs bubbles burn colorshift
      crumble decrypt errorcorrect expand fireworks highlight laseretch
      matrix middleout orbittingvolley overflow pour print rain
      randomsequence rings scattered slice slide spotlights spray
      swarm sweep synthgrid unstable vhstape waves wipe
    )

    # Function to check for any input (keyboard or mouse)
    check_input() {
      read -rsn1 -t 0.1 && return 0
      return 1
    }
    
    # Function to exit and kill ALL screensavers (not just this one)
    exit_all() {
      # Kill TTE first
      [[ -n "$TTE_PID" ]] && kill "$TTE_PID" 2>/dev/null
      # Spawn kill command in background so it can kill us too
      nohup omanix-screensaver-kill >/dev/null 2>&1 &
      exit 0
    }

    # Main loop - cycle through effects until input detected
    while true; do
      clear
      printf '\033[?25l'  # Ensure cursor stays hidden
      
      # Pick a random effect
      EFFECT="''${EFFECTS[$RANDOM % ''${#EFFECTS[@]}]}"
      
      # Run TTE with the selected effect in background
      ${tte}/bin/tte \
        --input-file ${logoFile} \
        --canvas-width 0 \
        --canvas-height 0 \
        --anchor-canvas c \
        --anchor-text c \
        "$EFFECT" \
        2>/dev/null &
      TTE_PID=$!
      
      # While TTE is running, check for input
      while kill -0 "$TTE_PID" 2>/dev/null; do
        if check_input; then
          exit_all
        fi
        sleep 0.1
      done
      
      wait "$TTE_PID" 2>/dev/null || true
      TTE_PID=""
      
      printf '\033[?25l'  # Re-hide cursor after effect completes
      
      # Check for input during the delay too
      for i in {1..20}; do
        if check_input; then
          exit_all
        fi
        sleep 0.1
      done
    done
  '';

  # Multi-monitor screensaver launcher
  screensaver = pkgs.writeShellScriptBin "omanix-screensaver" ''
    export PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:${pkgs.procps}/bin:$PATH"

    # Don't start if already locked
    if pidof hyprlock > /dev/null 2>&1; then
      exit 0
    fi

    # Don't start if screensaver is already running
    if pgrep -f "org.omanix.screensaver" > /dev/null 2>&1; then
      exit 0
    fi

    # Close walker if open to prevent UI conflicts
    pkill -f "walker" 2>/dev/null || true

    # Hide the mouse cursor by setting a very short inactive timeout
    hyprctl keyword cursor:inactive_timeout 1 2>/dev/null || true

    # Get all connected monitor names
    readarray -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
    
    # For each monitor, focus it first, then spawn the screensaver there
    for MONITOR in "''${MONITORS[@]}"; do
      # Focus this monitor - new windows will spawn here
      hyprctl dispatch focusmonitor "$MONITOR"
      sleep 0.2
      
      # Spawn the screensaver on the now-focused monitor
      hyprctl dispatch exec "ghostty --class=org.omanix.screensaver --fullscreen --cursor-style=bar --cursor-style-blink=false --cursor-color=black --cursor-text=black -e omanix-screensaver-effect"
      sleep 0.3
    done
  '';

  # Kill screensaver utility - more aggressive cleanup
  killScreensaver = pkgs.writeShellScriptBin "omanix-screensaver-kill" ''
    export PATH="${pkgs.hyprland}/bin:${pkgs.procps}/bin:${pkgs.coreutils}/bin:$PATH"
    
    # First, close the ghostty windows via Hyprland (graceful)
    hyprctl clients -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "org.omanix.screensaver") | .address' | while read -r addr; do
      [[ -n "$addr" ]] && hyprctl dispatch closewindow "address:$addr" 2>/dev/null || true
    done
    
    # Give windows a moment to close gracefully
    sleep 0.3
    
    # Kill any remaining screensaver effect processes (SIGTERM first)
    pkill -TERM -f "omanix-screensaver-effect" 2>/dev/null || true
    
    # Brief pause for graceful shutdown
    sleep 0.2
    
    # Force kill if still running (SIGKILL)
    pkill -KILL -f "omanix-screensaver-effect" 2>/dev/null || true
    pkill -KILL -f "org.omanix.screensaver" 2>/dev/null || true
    
    # Also kill any orphaned TTE processes
    pkill -KILL -f "terminaltexteffects" 2>/dev/null || true
    pkill -KILL -f "/tte " 2>/dev/null || true
    
    # Restore mouse cursor settings
    hyprctl keyword cursor:inactive_timeout 0 2>/dev/null || true
    
    exit 0
  '';

in
{
  home.packages = [
    tte
    screensaver
    screensaverEffect
    killScreensaver
  ];
  
  # Add a systemd user service to ensure cleanup on logout/shutdown
  systemd.user.services.omanix-screensaver-cleanup = {
    Unit = {
      Description = "Cleanup Omanix screensaver on shutdown";
      DefaultDependencies = false;
      Before = [ "shutdown.target" "reboot.target" "halt.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${killScreensaver}/bin/omanix-screensaver-kill";
      TimeoutStartSec = "5s";
    };
    Install = {
      WantedBy = [ "shutdown.target" "reboot.target" "halt.target" ];
    };
  };
}
