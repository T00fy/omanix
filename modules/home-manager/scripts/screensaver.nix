{ pkgs, config, ... }:
let
  tte = pkgs.python312Packages.terminaltexteffects;
  logoFile = ../../../assets/branding/logo.txt;

  screensaverEffect = pkgs.writeShellScriptBin "omanix-screensaver-effect" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.ncurses}/bin:${pkgs.procps}/bin:$PATH"

    TTE_PID=""

    # --- 1. Helper Functions (Restored) ---

    # Check for any input (keyboard key press) with a short timeout
    check_input() {
      read -rsn1 -t 0.1 && return 0
      return 1
    }

    # Exit and kill ALL screensavers
    exit_all() {
      # Kill the current TTE process if running
      [[ -n "$TTE_PID" ]] && kill "$TTE_PID" 2>/dev/null
      
      # Spawn external kill command (ensure this script exists in your config)
      nohup omanix-screensaver-kill >/dev/null 2>&1 &
      exit 0
    }

    cleanup() {
      [[ -n "$TTE_PID" ]] && kill "$TTE_PID" 2>/dev/null
      tput cnorm 2>/dev/null || true
      printf '\033[?25h' 2>/dev/null || true
      clear 2>/dev/null || true
      exit 0
    }

    trap cleanup EXIT INT TERM HUP QUIT

    # Setup terminal
    printf '\033]11;rgb:00/00/00\007'
    tput civis
    printf '\033[?25l'

    # Enable mouse tracking so we can detect mouse movement
    printf '\033[?1003h'

    EFFECTS=(
      beams binarypath blackhole bouncyballs bubbles burn colorshift
      crumble decrypt errorcorrect expand fireworks highlight laseretch
      matrix middleout orbittingvolley overflow pour print rain
      randomsequence rings scattered slice slide spotlights spray
      swarm sweep synthgrid unstable vhstape waves wipe
    )

    # --- 2. Main Loop (Restored Asynchronous Logic) ---

    while true; do
      clear
      printf '\033[?25l'

      EFFECT="''${EFFECTS[$RANDOM % ''${#EFFECTS[@]}]}"
      
      # Run TTE in the BACKGROUND (&) so we can check inputs
      ${tte}/bin/tte \
        --input-file ${logoFile} \
        --canvas-width 0 \
        --canvas-height 0 \
        --anchor-canvas c \
        --anchor-text c \
        "$EFFECT" \
        2>/dev/null &
      
      # Capture the PID of the running effect
      TTE_PID=$!

      # Loop while the effect is running to check for input
      while kill -0 "$TTE_PID" 2>/dev/null; do
        if check_input; then
          exit_all
        fi
        sleep 0.1
      done

      wait "$TTE_PID" 2>/dev/null || true
      TTE_PID=""

      printf '\033[?25l'

      # Sleep for 2 seconds between effects, BUT keep checking input
      for i in {1..20}; do
        if check_input; then
          exit_all
        fi
        sleep 0.1
      done
    done
  '';

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

     pkill -f "walker" 2>/dev/null || true
     hyprctl keyword cursor:inactive_timeout 1 2>/dev/null || true

     # Get workspace IDs for each monitor - spawn ALL at once without focus switching
     WORKSPACES=$(hyprctl monitors -j | jq -r '.[].activeWorkspace.id')

     for WS in $WORKSPACES; do
       # Use workspace rule to place window, no focus switching needed
       hyprctl dispatch exec "[workspace $WS silent; fullscreen; float]" "ghostty --class=org.omanix.screensaver --fullscreen --cursor-style=bar --cursor-style-blink=false --cursor-color=black --cursor-text=black -e omanix-screensaver-effect" &
     done

     # Wait for all spawns to complete
     wait
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
      Before = [
        "shutdown.target"
        "reboot.target"
        "halt.target"
      ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${killScreensaver}/bin/omanix-screensaver-kill";
      TimeoutStartSec = "5s";
    };
    Install = {
      WantedBy = [
        "shutdown.target"
        "reboot.target"
        "halt.target"
      ];
    };
  };
}
