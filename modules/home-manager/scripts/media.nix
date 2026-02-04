{ pkgs, ... }:
let
  audioSwitch = pkgs.writeShellScriptBin "omanix-cmd-audio-switch" ''
    export PATH="${pkgs.jq}/bin:${pkgs.pulseaudio}/bin:${pkgs.swayosd}/bin:${pkgs.hyprland}/bin:$PATH"

    # Get current focused monitor for OSD
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

    # Get Sinks
    SINKS=$(pactl -f json list sinks)
    COUNT=$(echo "$SINKS" | jq length)

    if [ "$COUNT" -eq 0 ]; then
      swayosd-client --monitor "$MONITOR" --custom-message "No audio devices"
      exit 1
    fi

    CURRENT=$(pactl get-default-sink)
    NAMES=$(echo "$SINKS" | jq -r '.[].name')

    # Cycle logic
    NEXT_SINK=""
    FOUND_CURRENT=false
    FIRST_SINK=""

    while IFS= read -r SINK; do
      if [ -z "$FIRST_SINK" ]; then FIRST_SINK="$SINK"; fi
      
      if [ "$FOUND_CURRENT" = true ]; then
        NEXT_SINK="$SINK"
        break
      fi
      if [ "$SINK" = "$CURRENT" ]; then FOUND_CURRENT=true; fi
    done <<< "$NAMES"

    if [ -z "$NEXT_SINK" ]; then NEXT_SINK="$FIRST_SINK"; fi

    pactl set-default-sink "$NEXT_SINK"

    DESC=$(echo "$SINKS" | jq -r --arg name "$NEXT_SINK" '.[] | select(.name == $name) | .description')
    swayosd-client --monitor "$MONITOR" --custom-message "$DESC" --custom-icon "audio-volume-high"
  '';
in
{
  home.packages = [
    audioSwitch

    pkgs.playerctl
    pkgs.brightnessctl
    pkgs.wireplumber
    pkgs.pavucontrol
  ];
}
