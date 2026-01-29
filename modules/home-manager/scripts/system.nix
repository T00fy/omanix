{ pkgs, ... }:
let
  # 1. Screenshot
  screenshot = pkgs.writeShellScriptBin "omanix-cmd-screenshot" ''
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

    # Cleanup any stuck instances
    pkill slurp && exit 0
    pkill wayfreeze

    # Arguments: Mode [smart|region|windows|fullscreen] | Dest [file|clipboard]
    MODE="''${1:-smart}"
    DEST="''${2:-file}"

    # Helper to get window rectangles from Hyprland
    get_rectangles() {
      local active_workspace
      active_workspace=$($HYPRCTL monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
      
      $HYPRCTL monitors -j | jq -r --arg ws "$active_workspace" '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
      $HYPRCTL clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
    }

    # Start Wayfreeze in background to freeze all monitors
    $WAYFREEZE & PID=$!
    sleep 0.1

    # Selection Logic
    case "$MODE" in
      region)
        SELECTION=$($SLURP 2>/dev/null)
        ;;
      windows)
        SELECTION=$(get_rectangles | $SLURP -r 2>/dev/null)
        ;;
      fullscreen)
        SELECTION=$($HYPRCTL monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
        ;;
      smart|*)
        RECTS=$(get_rectangles)
        SELECTION=$(echo "$RECTS" | $SLURP 2>/dev/null)

        # Smart Logic for tiny clicks
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

    # CRITICAL: Kill wayfreeze and wait for it to fully exit. 
    # If grim captures while wayfreeze is still active, it can result in a blurry/dim buffer.
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
    pkill wayfreeze

    # If no selection made, exit
    [ -z "$SELECTION" ] && exit 0

    # Ensure we are focusing the monitor under the cursor so Satty opens there
    $HYPRCTL dispatch focusmonitor +0 >/dev/null 2>&1

    # Processing Logic
    if [[ "$DEST" == "file" ]]; then
      # USE A TEMP FILE. This is the fix for blurry screenshots.
      # Piping into Satty often results in incorrect DPI scaling of the buffer.
      TEMP_FILE="/tmp/omanix-snap-$(date +%s).png"
      
      # Capture to physical file
      $GRIM -g "$SELECTION" "$TEMP_FILE"
      
      # Determine final destination
      FILE_NAME="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
      
      # Open in editor using the physical file
      $SATTY --filename "$TEMP_FILE" \
          --output-filename "$FILE_NAME" \
          --early-exit \
          --copy-command "$WL_COPY"
          
      # Cleanup
      rm -f "$TEMP_FILE"
    else
      # Clipboard mode - quality is fine here as clipboard accepts the raw stream
      $GRIM -g "$SELECTION" - | $WL_COPY
      $NOTIFY "Screenshot copied to clipboard"
    fi
  '';

  # 2. Lock Screen (New Upstream Parity)
  lockScreen = pkgs.writeShellScriptBin "omanix-lock-screen" ''
    # Lock the screen immediately
    pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock &

    # Reset keyboard layout to default (security best practice)
    ${pkgs.hyprland}/bin/hyprctl switchxkblayout all 0 > /dev/null 2>&1

    # Bitwarden CLI Lock (Optional integration)
    if command -v bw &> /dev/null; then
      if bw status | grep -q "unlocked"; then
        bw lock
        ${pkgs.libnotify}/bin/notify-send "Vault Locked" "Bitwarden CLI vault has been locked."
      fi
    fi
  '';

  # 3. Shutdown / Reboot (Graceful)
  shutdown = pkgs.writeShellScriptBin "omanix-cmd-shutdown" ''
    # Close all windows first to save state
    ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r ".[].address" | xargs -r -I{} ${pkgs.hyprland}/bin/hyprctl dispatch closewindow address:{}
    sleep 1
    systemctl poweroff
  '';

  reboot = pkgs.writeShellScriptBin "omanix-cmd-reboot" ''
    ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r ".[].address" | xargs -r -I{} ${pkgs.hyprland}/bin/hyprctl dispatch closewindow address:{}
    sleep 1
    systemctl reboot
  '';
in
{
  home.packages = [
    screenshot
    lockScreen
    shutdown
    reboot

    # System Dependencies
    pkgs.satty
    pkgs.wayfreeze
    pkgs.grim
    pkgs.slurp
    pkgs.wl-clipboard
    pkgs.libnotify
    pkgs.hyprpicker
    pkgs.blueman
    pkgs.bitwarden-cli
    pkgs.procps # for pkill
  ];
}
