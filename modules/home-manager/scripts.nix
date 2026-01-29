{ pkgs, ... }:
let
  # The full Omarchy screenshot logic
  screenshot = pkgs.writeShellScriptBin "omarchy-cmd-screenshot" ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gawk}/bin:${pkgs.procps}/bin:$PATH"

    # Define binaries
    GRIM="${pkgs.grim}/bin/grim"
    SLURP="${pkgs.slurp}/bin/slurp"
    SATTY="${pkgs.satty}/bin/satty"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    WAYFREEZE="${pkgs.wayfreeze}/bin/wayfreeze"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"

    # 1. Determine Output Directory
    if [[ -f ~/.config/user-dirs.dirs ]]; then
      source ~/.config/user-dirs.dirs
      OUTPUT_DIR="''${OMARCHY_SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures}}"
    else
      OUTPUT_DIR="$HOME/Pictures"
    fi

    if [[ ! -d "$OUTPUT_DIR" ]]; then
      $NOTIFY "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
      mkdir -p "$OUTPUT_DIR"
    fi

    # Cleanup any stuck slurp instances
    pkill slurp && exit 0

    # Arguments: Mode [smart|region|windows|fullscreen] | Dest [file|clipboard]
    MODE="''${1:-smart}"
    DEST="''${2:-file}"

    # Helper to get window rectangles from Hyprland
    get_rectangles() {
      local active_workspace
      active_workspace=$($HYPRCTL monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
      
      # Monitor geometry
      $HYPRCTL monitors -j | jq -r --arg ws "$active_workspace" '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
      
      # Window geometry
      $HYPRCTL clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    }

    # Selection Logic
    case "$MODE" in
      region)
        $WAYFREEZE & PID=$!
        sleep .1
        SELECTION=$($SLURP 2>/dev/null)
        kill $PID 2>/dev/null
        ;;
      windows)
        $WAYFREEZE & PID=$!
        sleep .1
        SELECTION=$(get_rectangles | $SLURP -r 2>/dev/null)
        kill $PID 2>/dev/null
        ;;
      fullscreen)
        SELECTION=$($HYPRCTL monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
        ;;
      smart|*)
        RECTS=$(get_rectangles)
        $WAYFREEZE & PID=$!
        sleep .1
        SELECTION=$(echo "$RECTS" | $SLURP 2>/dev/null)
        kill $PID 2>/dev/null

        # Smart Logic: If selection is tiny (< 20px area), assumes a click on a specific window/output
        if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
          W="''${BASH_REMATCH[3]}"
          H="''${BASH_REMATCH[4]}"
          AREA=$(( W * H ))
          
          if (( AREA < 20 )); then
            CLICK_X="''${BASH_REMATCH[1]}"
            CLICK_Y="''${BASH_REMATCH[2]}"

            while IFS= read -r rect; do
              if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
                RX="''${BASH_REMATCH[1]}"
                RY="''${BASH_REMATCH[2]}"
                RW="''${BASH_REMATCH[3]}"
                RH="''${BASH_REMATCH[4]}"

                if (( CLICK_X >= RX && CLICK_X < RX+RW && CLICK_Y >= RY && CLICK_Y < RY+RH )); then
                  SELECTION="$RX,$RY ''${RW}x''${RH}"
                  break
                fi
              fi
            done <<< "$RECTS"
          fi
        fi
        ;;
    esac

    [ -z "$SELECTION" ] && exit 0

    # Processing Logic
    if [[ "$DEST" == "file" ]]; then
      # "File" mode in Omarchy means open in Satty (Editor)
      # Satty handles the actual saving to file and copying to clipboard after edit
      FILE_NAME="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
      
      $GRIM -g "$SELECTION" - | \
        $SATTY --filename - \
          --output-filename "$FILE_NAME" \
          --early-exit \
          --copy-command "$WL_COPY"
          
      # Note: Satty handles notifications internally usually, 
      # but we can add one if Satty exits successfully
    else
      # "Clipboard" mode skips the editor and goes straight to clipboard
      $GRIM -g "$SELECTION" - | $WL_COPY
      $NOTIFY "Screenshot copied to clipboard"
    fi
  '';

  launchBrowser = pkgs.writeShellScriptBin "omarchy-launch-browser" ''
    BROWSER="firefox"
    if [[ "$1" == "--private" ]]; then
      exec $BROWSER --private-window
    else
      exec $BROWSER
    fi
  '';

in
{
  home.packages = [
    screenshot
    launchBrowser
    
    # Dependencies required for the script
    pkgs.satty        # The annotation tool
    pkgs.wayfreeze    # Freezes screen for selections
    pkgs.grim         # Screenshot tool
    pkgs.slurp        # Selection tool
    pkgs.wl-clipboard # Clipboard utils
    pkgs.jq           # JSON processor
    
    # Other existing tools
    pkgs.libnotify
    pkgs.swayosd
    pkgs.playerctl
    pkgs.brightnessctl
    pkgs.wireplumber 
    pkgs.hyprpicker
    pkgs.wofi
    pkgs.pavucontrol
    pkgs.blueman
    pkgs.nautilus
    
    # Browsers
    pkgs.chromium
    pkgs.firefox
  ];
}
