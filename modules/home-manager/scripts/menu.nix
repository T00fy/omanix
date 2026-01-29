{
  pkgs,
  inputs,
  omarchyLib,
  ...
}:
let
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;
  elephantPkg = inputs.elephant.packages.${pkgs.system}.default;

  # ═══════════════════════════════════════════════════════════════════
  # HELP SYSTEM
  # ═══════════════════════════════════════════════════════════════════
  
  availableThemes = builtins.attrNames omarchyLib.themes;
  themeListFormatted = builtins.concatStringsSep "\n" (map (t: "- ${t}") availableThemes);

  showStyleHelp = pkgs.writeShellScriptBin "omarchy-show-style-help" ''
    HELP_FILE=$(mktemp /tmp/omanix-help-XXXXXX.md)
    sed 's/{{THEME_LIST}}/${themeListFormatted}/' ${../../../docs/style.md} > "$HELP_FILE"
    
    if command -v glow &> /dev/null; then
      ghostty --class="org.omarchy.terminal" -e sh -c "glow -p '$HELP_FILE'; rm '$HELP_FILE'"
    else
      ghostty --class="org.omarchy.terminal" -e sh -c "less '$HELP_FILE'; rm '$HELP_FILE'"
    fi
  '';

  showSetupHelp = pkgs.writeShellScriptBin "omarchy-show-setup-help" ''
    TOPIC="$1"
    DOCS_DIR="${../../../docs}"
    
    case "$TOPIC" in
      hyprland)  DOC_FILE="$DOCS_DIR/hyprland.md" ;;
      hypridle)  DOC_FILE="$DOCS_DIR/hypridle.md" ;;
      hyprlock)  DOC_FILE="$DOCS_DIR/hyprlock.md" ;;
      waybar)    DOC_FILE="$DOCS_DIR/waybar.md" ;;
      walker)    DOC_FILE="$DOCS_DIR/walker.md" ;;
      *)
        echo "Unknown topic: $TOPIC"
        exit 1
        ;;
    esac

    if command -v glow &> /dev/null; then
      ghostty --class="org.omarchy.terminal" -e sh -c "glow -p '$DOC_FILE'"
    else
      ghostty --class="org.omarchy.terminal" -e sh -c "less '$DOC_FILE'"
    fi
  '';

  # ═══════════════════════════════════════════════════════════════════
  # MENU LAUNCHER
  # Uses Elephant's native menu system for hierarchical + searchable menus
  # ═══════════════════════════════════════════════════════════════════

  menu = pkgs.writeShellScriptBin "omarchy-menu" ''
    # Open the Omarchy menu via Walker with the "omarchy" set
    # This enables universal search across ALL menu items while maintaining hierarchy
    ${walkerPkg}/bin/walker -s omarchy
  '';

  # ═══════════════════════════════════════════════════════════════════
  # KEYBINDINGS MENU
  # ═══════════════════════════════════════════════════════════════════

  keybindingsMenu = pkgs.writeShellScriptBin "omarchy-menu-keybindings" ''
    export PATH="${pkgs.gawk}/bin:${pkgs.libxkbcommon}/bin:${pkgs.hyprland}/bin:${pkgs.jq}/bin:$PATH"

    declare -A KEYCODE_SYM_MAP

    build_keymap_cache() {
      local keymap
      keymap="$(xkbcli compile-keymap)" || {
        echo "Failed to compile keymap" >&2
        return 1
      }

      while IFS=, read -r code sym; do
        [[ -z "$code" || -z "$sym" ]] && continue
        KEYCODE_SYM_MAP["$code"]="$sym"
      done < <(
        awk '
          BEGIN { sec = "" }
          /xkb_keycodes/ { sec = "codes"; next }
          /xkb_symbols/  { sec = "syms";  next }
          sec == "codes" {
            if (match($0, /<([A-Za-z0-9_]+)>\s*=\s*([0-9]+)\s*;/, m)) code_by_name[m[1]] = m[2]
          }
          sec == "syms" {
            if (match($0, /key\s*<([A-Za-z0-9_]+)>\s*\{\s*\[\s*([^, \]]+)/, m)) sym_by_name[m[1]] = m[2]
          }
          END {
            for (k in code_by_name) {
              c = code_by_name[k]
              s = sym_by_name[k]
              if (c != "" && s != "" && s != "NoSymbol") print c "," s
            }
          }
        ' <<<"$keymap"
      )
    }

    lookup_keycode_cached() {
      printf '%s\n' "''${KEYCODE_SYM_MAP[$1]}"
    }

    parse_keycodes() {
      while IFS= read -r line; do
        if [[ "$line" =~ code:([0-9]+) ]]; then
          code="''${BASH_REMATCH[1]}"
          symbol=$(lookup_keycode_cached "$code")
          echo "''${line/code:''${code}/$symbol}"
        elif [[ "$line" =~ mouse:([0-9]+) ]]; then
          code="''${BASH_REMATCH[1]}"
          case "$code" in
            272) symbol="LEFT MOUSE BUTTON" ;;
            273) symbol="RIGHT MOUSE BUTTON" ;;
            274) symbol="MIDDLE MOUSE BUTTON" ;;
            *)   symbol="mouse:''${code}" ;;
          esac
          echo "''${line/mouse:''${code}/$symbol}"
        else
          echo "$line"
        fi
      done
    }

    dynamic_bindings() {
      hyprctl -j binds |
        jq -r '.[] | {modmask, key, keycode, description, dispatcher, arg} | "\(.modmask),\(.key)@\(.keycode),\(.description),\(.dispatcher),\(.arg)"' |
        sed -r \
          -e 's/null//' \
          -e 's/@0//' \
          -e 's/,@/,code:/' \
          -e 's/^0,/,/' \
          -e 's/^1,/SHIFT,/' \
          -e 's/^4,/CTRL,/' \
          -e 's/^5,/SHIFT CTRL,/' \
          -e 's/^8,/ALT,/' \
          -e 's/^9,/SHIFT ALT,/' \
          -e 's/^12,/CTRL ALT,/' \
          -e 's/^13,/SHIFT CTRL ALT,/' \
          -e 's/^64,/SUPER,/' \
          -e 's/^65,/SUPER SHIFT,/' \
          -e 's/^68,/SUPER CTRL,/' \
          -e 's/^69,/SUPER SHIFT CTRL,/' \
          -e 's/^72,/SUPER ALT,/' \
          -e 's/^73,/SUPER SHIFT ALT,/' \
          -e 's/^76,/SUPER CTRL ALT,/' \
          -e 's/^77,/SUPER SHIFT CTRL ALT,/'
    }

    parse_bindings() {
      awk -F, '
    {
        key_combo = $1 " + " $2;
        gsub(/^[ \t]*\+?[ \t]*/, "", key_combo);
        gsub(/[ \t]+$/, "", key_combo);
        action = $3;

        if (action == "") {
            for (i = 4; i <= NF; i++) {
                action = action $i (i < NF ? "," : "");
            }
            sub(/,$/, "", action);
            gsub(/(^|,)[[:space:]]*exec[[:space:]]*,?/, "", action);
            gsub(/^[ \t]+|[ \t]+$/, "", action);
            gsub(/[ \t]+/, " ", key_combo);
            gsub(/&/, "\\&amp;", action);
            gsub(/</, "\\&lt;", action);
            gsub(/>/, "\\&gt;", action);
            gsub(/"/, "\\&quot;", action);
            gsub(/'"'"'/, "\\&apos;", action);
        }

        if (action != "") {
            printf "%-35s → %s\n", key_combo, action;
        }
    }'
    }

    output_keybindings() {
      build_keymap_cache
      dynamic_bindings | sort -u | parse_keycodes | parse_bindings
    }

    if [[ "$1" == "--print" || "$1" == "-p" ]]; then
      output_keybindings
    else
      monitor_height=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .height')
      menu_height=$((monitor_height * 40 / 100))
      
      output_keybindings | omarchy-launch-walker --dmenu -p 'Keybindings' --width 800 --height "$menu_height"
    fi
  '';

  # ═══════════════════════════════════════════════════════════════════
  # UTILITY SCRIPTS
  # ═══════════════════════════════════════════════════════════════════

  restartWalker = pkgs.writeShellScriptBin "omarchy-restart-walker" ''
    systemctl --user restart elephant.service
    sleep 0.5
    systemctl --user restart walker.service
    ${pkgs.libnotify}/bin/notify-send "Walker" "Services have been restarted"
  '';

  launchAudio = pkgs.writeShellScriptBin "omarchy-launch-audio" ''
    ${pkgs.pavucontrol}/bin/pavucontrol &
  '';

  launchWifi = pkgs.writeShellScriptBin "omarchy-launch-wifi" ''
    omarchy-launch-or-focus-tui impala
  '';

  launchBluetooth = pkgs.writeShellScriptBin "omarchy-launch-bluetooth" ''
    omarchy-launch-or-focus-tui bluetui
  '';

  toggleWaybar = pkgs.writeShellScriptBin "omarchy-toggle-waybar" ''
    if pgrep -x waybar > /dev/null; then
      pkill waybar
    else
      waybar &
    fi
  '';

in
{
  home.packages = [
    menu
    showStyleHelp
    showSetupHelp
    keybindingsMenu
    restartWalker
    launchAudio
    launchWifi
    launchBluetooth
    toggleWaybar
    pkgs.networkmanagerapplet
    pkgs.libxkbcommon
    pkgs.gawk
    pkgs.localsend
    pkgs.impala
    pkgs.bluetui
    pkgs.glow
  ];
}
