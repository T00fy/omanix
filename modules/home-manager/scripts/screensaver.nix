{ pkgs, config, ... }:
let
  tte = pkgs.python312Packages.terminaltexteffects;
  logoFile = ../../../assets/branding/logo.txt;

  # The effect runner (runs inside the terminal)
  screensaverEffect = pkgs.writeShellScriptBin "omanix-screensaver-effect" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.ncurses}/bin:${pkgs.hyprland}/bin:$PATH"

    # Force pure black background (OLED black)
    printf '\033]11;rgb:00/00/00\007'

    # Hide the terminal cursor completely
    tput civis
    printf '\033[?25l'

    # Cleanup on exit - restore cursor settings and kill all screensavers
    cleanup() {
      # Disable mouse tracking
      printf '\033[?1003l'
      tput cnorm
      printf '\033[?25h'
      # Restore mouse cursor
      hyprctl keyword cursor:inactive_timeout 0 2>/dev/null || true
      # Kill ALL screensaver instances (not just this one)
      pkill -f "omanix-screensaver-effect" 2>/dev/null || true
      clear
    }
    trap cleanup EXIT INT TERM HUP

    # Enable mouse tracking so we can detect mouse movement
    printf '\033[?1003h'

    # Available effects (excluding dev_worm which doesn't work well with logos)
    EFFECTS=(
      beams
      binarypath
      blackhole
      bouncyballs
      bubbles
      burn
      colorshift
      crumble
      decrypt
      errorcorrect
      expand
      fireworks
      highlight
      laseretch
      matrix
      middleout
      orbittingvolley
      overflow
      pour
      print
      rain
      randomsequence
      rings
      scattered
      slice
      slide
      spotlights
      spray
      swarm
      sweep
      synthgrid
      unstable
      vhstape
      waves
      wipe
    )

    # Function to check for any input (keyboard or mouse)
    check_input() {
      read -rsn1 -t 0.1 && return 0
      return 1
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
      while kill -0 $TTE_PID 2>/dev/null; do
        if check_input; then
          kill $TTE_PID 2>/dev/null || true
          wait $TTE_PID 2>/dev/null || true
          exit 0
        fi
        sleep 0.1
      done
      
      wait $TTE_PID 2>/dev/null || true
      
      printf '\033[?25l'  # Re-hide cursor after effect completes
      
      # Check for input during the delay too
      for i in {1..20}; do
        if check_input; then
          exit 0
        fi
        sleep 0.1
      done
    done
  '';

  # Multi-monitor screensaver launcher
  screensaver = pkgs.writeShellScriptBin "omanix-screensaver" ''
    export PATH="${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.coreutils}/bin:$PATH"

    # Don't start if already locked
    if pidof hyprlock > /dev/null 2>&1; then
      exit 0
    fi

    # Don't start if screensaver is already running
    if pgrep -f "omanix-screensaver-effect" > /dev/null 2>&1; then
      exit 0
    fi

    # Close walker if open to prevent UI conflicts
    pkill -f "walker" 2>/dev/null || true

    # Hide the mouse cursor by setting a very short inactive timeout
    hyprctl keyword cursor:inactive_timeout 1

    # Get all connected monitor names
    readarray -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name')
    
    # For each monitor, focus it first, then spawn the screensaver there
    for MONITOR in "''${MONITORS[@]}"; do
      # Focus this monitor - new windows will spawn here
      hyprctl dispatch focusmonitor "$MONITOR"
      sleep 0.2
      
      # Spawn the screensaver on the now-focused monitor
      # Use cursor-style=bar with blink to make it invisible, and set cursor color to black
      hyprctl dispatch exec "ghostty --class=org.omanix.screensaver --fullscreen --cursor-style=bar --cursor-style-blink=false --cursor-color=black --cursor-text=black -e omanix-screensaver-effect"
      sleep 0.5
    done
  '';

  # Kill screensaver utility
  killScreensaver = pkgs.writeShellScriptBin "omanix-screensaver-kill" ''
    export PATH="${pkgs.hyprland}/bin:$PATH"
    
    # Kill all screensaver effect processes
    pkill -f "omanix-screensaver-effect" 2>/dev/null || true
    pkill -f "org.omanix.screensaver" 2>/dev/null || true
    
    # Restore mouse cursor settings
    hyprctl keyword cursor:inactive_timeout 0
    hyprctl keyword cursor:hide_on_key_press false
  '';

in
{
  home.packages = [
    tte
    screensaver
    screensaverEffect
    killScreensaver
  ];
}
