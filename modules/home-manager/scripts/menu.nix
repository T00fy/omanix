{
  pkgs,
  inputs,
  omanixLib,
  config,
  ...
}:
let
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;
  availableThemes = builtins.attrNames omanixLib.themes;
  themeListFormatted = builtins.concatStringsSep "\n" (map (t: "- ${t}") availableThemes);

  # ═══════════════════════════════════════════════════════════════════
  # THEME DATA & TEMPLATES
  # ═══════════════════════════════════════════════════════════════════
  themesJson = pkgs.writeText "omanix-themes.json" (
    builtins.toJSON (builtins.mapAttrs (name: val: val.assets.wallpapers) omanixLib.themes)
  );

  wallpaperHelpTemplate = pkgs.writeText "wallpaper-help.md" ''
    # Theme Change: ${"$"}{THEME_NAME}

    You are currently previewing wallpaper **#${"$"}{WP_INDEX}**.
    
    To make this permanent, update your `flake.nix` or Home Manager config:

    ```nix
    omanix = {
      theme = "${"$"}{THEME_NAME}";
      # If 0, this line is optional
      wallpaperIndex = ${"$"}{WP_INDEX};
    };
    ```

    **Next Steps:**
    1. Edit your config.
    2. Run your rebuild command (e.g., `rebuild`).
    3. The preview will persist until you reboot or rebuild.
  '';

  # ═══════════════════════════════════════════════════════════════════
  # HELP SYSTEM
  # ═══════════════════════════════════════════════════════════════════
  showStyleHelp = pkgs.writeShellScriptBin "omanix-show-style-help" ''
    HELP_FILE=$(mktemp /tmp/omanix-help-XXXXXX.md)
    sed 's/{{THEME_LIST}}/${themeListFormatted}/' ${../../../docs/style.md} > "$HELP_FILE"

    if command -v glow &> /dev/null; then
      # CHANGED: org.omanix.float -> org.omanix.terminal (matches rules.nix)
      ghostty --class="org.omanix.terminal" -e sh -c "glow -p '$HELP_FILE'; rm '$HELP_FILE'"
    else
      ghostty --class="org.omanix.terminal" -e sh -c "less '$HELP_FILE'; rm '$HELP_FILE'"
    fi
  '';

  showSetupHelp = pkgs.writeShellScriptBin "omanix-show-setup-help" ''
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
      ghostty --class="org.omanix.terminal" -e sh -c "glow -p '$DOC_FILE'"
    else
      ghostty --class="org.omanix.terminal" -e sh -c "less '$DOC_FILE'"
    fi
  '';

  # ═══════════════════════════════════════════════════════════════════
  # INTERACTIVE THEME SWITCHER
  # ═══════════════════════════════════════════════════════════════════
  styleMenu = pkgs.writeShellScriptBin "omanix-menu-style" ''
    export PATH="${pkgs.jq}/bin:${pkgs.swaybg}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:$PATH"
    
    THEMES_FILE="${themesJson}"
    TEMPLATE_FILE="${wallpaperHelpTemplate}"
    WALKER="${walkerPkg}/bin/walker"

    # 1. Select Theme
    THEME_NAME=$(jq -r 'keys[]' "$THEMES_FILE" | $WALKER --dmenu --placeholder "Select Theme...")
    [ -z "$THEME_NAME" ] && exit 0

    # 2. Select Wallpaper (Format: "Index: Path")
    WP_SELECTION=$(jq -r --arg t "$THEME_NAME" '.[$t] | to_entries | .[] | "\(.key): \(.value)"' "$THEMES_FILE" | \
      $WALKER --dmenu --placeholder "Select Wallpaper for $THEME_NAME...")
    [ -z "$WP_SELECTION" ] && exit 0

    # Extract Index and Path
    WP_INDEX=$(echo "$WP_SELECTION" | cut -d: -f1)
    WP_PATH=$(echo "$WP_SELECTION" | cut -d: -f2 | xargs)

    # 3. Hot-Reload Preview
    pkill swaybg
    swaybg -i "$WP_PATH" -m fill & 

    # 4. Show Instructions
    export THEME_NAME
    export WP_INDEX
    
    HELP_TEXT=$(envsubst < "$TEMPLATE_FILE")
    
    TMP_HELP=$(mktemp)
    echo "$HELP_TEXT" > "$TMP_HELP"
    
    # CHANGED: org.omanix.float -> org.omanix.terminal (matches rules.nix)
    ghostty --class="org.omanix.terminal" -e sh -c "${pkgs.glow}/bin/glow -p '$TMP_HELP'; rm '$TMP_HELP'"
  '';

  # ═══════════════════════════════════════════════════════════════════
  # MAIN MENU
  # ═══════════════════════════════════════════════════════════════════
  menu = pkgs.writeShellScriptBin "omanix-menu" ''
    WALKER="${walkerPkg}/bin/walker"

    menu_cmd() {
      local placeholder="$1"
      local options="$2"
      echo -e "$options" | "$WALKER" --dmenu --width 295 --minheight 1 --maxheight 630 --placeholder "$placeholder…"
    }

    back_to() { "$1"; }

    show_main_menu() {
      CHOICE=$(menu_cmd "Go" "󰀻  Apps\n󰧑  Learn\n󱓞  Trigger\n󰏘  Style\n󰒓  Setup\n󰍛  System")
      go_to_menu "$CHOICE"
    }

    go_to_menu() {
      case "''${1,,}" in
        *apps*)    omanix-launch-walker ;;
        *learn*)   show_learn_menu ;;
        *trigger*) show_trigger_menu ;;
        *style*)   show_style_menu ;;
        *setup*)   show_setup_menu ;;
        *system*)  show_system_menu ;;
        *) ;;
      esac
    }

    # ... [Rest of the sub-menus remain unchanged] ...
    
    # REPEATED HERE FOR CLARITY - COPY THIS WHOLE FILE
    show_learn_menu() {
      CHOICE=$(menu_cmd "Learn" "󰌌  Keybindings\n󰖟  Hyprland\n󱄅  NixOS Wiki\n󰊠  Neovim\n󱆃  Bash")
      case "$CHOICE" in
        *Keybindings*) omanix-menu-keybindings ;;
        *Hyprland*)    xdg-open "https://wiki.hyprland.org" ;;
        *NixOS*)       xdg-open "https://wiki.nixos.org" ;;
        *Neovim*)      xdg-open "https://neovim.io/doc/" ;;
        *Bash*)        xdg-open "https://www.gnu.org/software/bash/manual/" ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_trigger_menu() {
      CHOICE=$(menu_cmd "Trigger" "󰄀  Capture\n󰤲  Share\n󰃉  Color Picker")
      case "$CHOICE" in
        *Capture*) show_capture_menu ;;
        *Share*)   show_share_menu ;;
        *Color*)   ${pkgs.hyprpicker}/bin/hyprpicker -a ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_capture_menu() {
      CHOICE=$(menu_cmd "Capture" "󰹑  Screenshot\n󰻃  Screenrecord")
      case "$CHOICE" in
        *Screenshot*)   show_screenshot_menu ;;
        *Screenrecord*) show_screenrecord_menu ;;
        *) back_to show_trigger_menu ;;
      esac
    }

    show_screenshot_menu() {
      CHOICE=$(menu_cmd "Screenshot" "󰏫  Snap with Editing\n󰅍  Straight to Clipboard")
      case "$CHOICE" in
        *Editing*)   omanix-cmd-screenshot smart ;;
        *Clipboard*) omanix-cmd-screenshot smart clipboard ;;
        *) back_to show_capture_menu ;;
      esac
    }

    show_screenrecord_menu() {
      CHOICE=$(menu_cmd "Screenrecord" "󰍹  Full Screen\n󰆞  Region\n󰓛  Stop Recording")
      case "$CHOICE" in
        *Full*)   ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Full screen recording not yet implemented" ;;
        *Region*) ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Region recording not yet implemented" ;;
        *Stop*)   pkill -SIGINT wf-recorder || pkill -SIGINT wl-screenrec ;;
        *) back_to show_capture_menu ;;
      esac
    }

    show_share_menu() {
      CHOICE=$(menu_cmd "Share" "󰷛  LocalSend")
      case "$CHOICE" in
        *LocalSend*) localsend_app ;;
        *) back_to show_trigger_menu ;;
      esac
    }

    show_style_menu() {
      CHOICE=$(menu_cmd "Style" "🎨  Change Theme & Wallpaper\n📖  Read Style Guide")
      case "$CHOICE" in
        *Change*) omanix-menu-style ;;
        *Read*)   omanix-show-style-help ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_setup_menu() {
      CHOICE=$(menu_cmd "Setup" "󰕾  Audio\n󰖩  Wifi\n󰂯  Bluetooth\n󰋁  Hyprland\n󰒲  Hypridle\n󰌾  Hyprlock\n󰍜  Waybar\n󰌧  Walker")
      case "$CHOICE" in
        *Audio*)     omanix-launch-audio ;;
        *Wifi*)      omanix-launch-wifi ;;
        *Bluetooth*) omanix-launch-bluetooth ;;
        *Hyprland*)  omanix-show-setup-help hyprland ;;
        *Hypridle*)  omanix-show-setup-help hypridle ;;
        *Hyprlock*)  omanix-show-setup-help hyprlock ;;
        *Waybar*)    omanix-show-setup-help waybar ;;
        *Walker*)    omanix-show-setup-help walker ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_system_menu() {
      CHOICE=$(menu_cmd "System" "󰌾  Lock\n󱄄  Screensaver\n󰒲  Suspend\n󰜉  Restart\n󰐥  Shutdown")
      case "$CHOICE" in
        *Lock*)        omanix-lock-screen ;;
        *Screensaver*) omanix-screensaver ;;
        *Suspend*)     systemctl suspend ;;
        *Restart*)     omanix-cmd-reboot ;;
        *Shutdown*)    omanix-cmd-shutdown ;;
        *) back_to show_main_menu ;;
      esac
    }

    if [[ -n "$1" ]]; then
      go_to_menu "$1"
    else
      show_main_menu
    fi
  '';

  # ═══════════════════════════════════════════════════════════════════
  # KEYBINDINGS MENU
  # ═══════════════════════════════════════════════════════════════════
  keybindingsMenu = pkgs.writeShellScriptBin "omanix-menu-keybindings" ''
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
      
      output_keybindings | omanix-launch-walker --dmenu -p 'Keybindings' --width 800 --height "$menu_height"
    fi
  '';

  # ═══════════════════════════════════════════════════════════════════
  # UTILITY SCRIPTS
  # ═══════════════════════════════════════════════════════════════════
  restartWalker = pkgs.writeShellScriptBin "omanix-restart-walker" ''
    systemctl --user restart elephant.service
    sleep 0.5
    systemctl --user restart walker.service
    ${pkgs.libnotify}/bin/notify-send "Walker" "Services have been restarted"
  '';

  launchAudio = pkgs.writeShellScriptBin "omanix-launch-audio" ''
    ${pkgs.pavucontrol}/bin/pavucontrol &
  '';

  launchWifi = pkgs.writeShellScriptBin "omanix-launch-wifi" ''
    omanix-launch-or-focus-tui impala
  '';

  launchBluetooth = pkgs.writeShellScriptBin "omanix-launch-bluetooth" ''
    omanix-launch-or-focus-tui bluetui
  '';

  toggleWaybar = pkgs.writeShellScriptBin "omanix-toggle-waybar" ''
    if pgrep -x waybar > /dev/null; then
      pkill waybar
    else
      waybar &
    fi
  '';

in
{
  home.packages = [
    # Menu Scripts
    menu
    styleMenu
    showStyleHelp
    showSetupHelp
    keybindingsMenu

    # Utility Scripts
    restartWalker
    launchAudio
    launchWifi
    launchBluetooth
    toggleWaybar

    # Dependencies
    pkgs.networkmanagerapplet
    pkgs.libxkbcommon
    pkgs.gawk
    pkgs.gnused
    pkgs.localsend
    pkgs.impala
    pkgs.bluetui
    pkgs.glow
    pkgs.envsubst
    pkgs.jq
    pkgs.swaybg
  ];
}
