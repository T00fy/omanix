{
  pkgs,
  inputs,
  omarchyLib,
  ...
}:
let
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;

  # Get list of themes available in the library for the Style menu
  availableThemes = builtins.attrNames omarchyLib.themes;
  # Format them for Walker (Icon + Name)
  themeListStr = builtins.concatStringsSep "\\n" (map (t: "󰸌  " + t) availableThemes);

  # The Main Omarchy Menu
  menu = pkgs.writeShellScriptBin "omarchy-menu" ''
    WALKER="${walkerPkg}/bin/walker"

    # Helper to show a walker dmenu with Omarchy styling
    menu_cmd() {
      local placeholder="$1"
      local options="$2"
      echo -e "$options" | "$WALKER" --dmenu --width 295 --minheight 1 --maxheight 630 --placeholder "$placeholder…"
    }

    back_to() {
      "$1"
    }

    show_main_menu() {
      CHOICE=$(menu_cmd "Go" "󰀻  Apps\n󰧑  Learn\n󱓞  Trigger\n  Style\n  Setup\n  System")
      go_to_menu "$CHOICE"
    }

    go_to_menu() {
      case "''${1,,}" in
        *apps*) omarchy-launch-walker ;;
        *learn*) show_learn_menu ;;
        *trigger*) show_trigger_menu ;;
        *system*) show_system_menu ;;
        *style*) show_style_menu ;;
        *setup*) show_setup_menu ;;
        *) ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # LEARN MENU
    # ═══════════════════════════════════════════════════════════════════
    show_learn_menu() {
      CHOICE=$(menu_cmd "Learn" "  Keybindings\n  Hyprland\n  NixOS Wiki\n  Neovim\n󱆃  Bash")
      case "$CHOICE" in
        *Keybindings*) omarchy-menu-keybindings ;;
        *Hyprland*) xdg-open "https://wiki.hyprland.org" ;;
        *NixOS*) xdg-open "https://wiki.nixos.org" ;;
        *Neovim*) xdg-open "https://neovim.io/doc/" ;;
        *Bash*) xdg-open "https://www.gnu.org/software/bash/manual/" ;;
        *) back_to show_main_menu ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # TRIGGER MENU
    # ═══════════════════════════════════════════════════════════════════
    show_trigger_menu() {
      CHOICE=$(menu_cmd "Trigger" "  Capture\n  Share\n󰃉  Color Picker")
      case "$CHOICE" in
        *Capture*) show_capture_menu ;;
        *Share*) show_share_menu ;;
        *Color*) ${pkgs.hyprpicker}/bin/hyprpicker -a ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_capture_menu() {
      CHOICE=$(menu_cmd "Capture" "  Screenshot\n  Screenrecord")
      case "$CHOICE" in
        *Screenshot*) show_screenshot_menu ;;
        *Screenrecord*) show_screenrecord_menu ;;
        *) back_to show_trigger_menu ;;
      esac
    }

    # Fixed Screenshot menu to match upstream (Editing vs Clipboard)
    show_screenshot_menu() {
      CHOICE=$(menu_cmd "Screenshot" "  Snap with Editing\n  Straight to Clipboard")
      case "$CHOICE" in
        *Editing*) omarchy-cmd-screenshot smart ;;
        *Clipboard*) omarchy-cmd-screenshot smart clipboard ;;
        *) back_to show_capture_menu ;;
      esac
    }

    show_screenrecord_menu() {
      CHOICE=$(menu_cmd "Screenrecord" "󰍹  Full Screen\n  Region\n  Stop Recording")
      case "$CHOICE" in
        *Full*) ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Full screen recording not yet implemented" ;;
        *Region*) ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Region recording not yet implemented" ;;
        *Stop*) pkill -SIGINT wf-recorder || pkill -SIGINT wl-screenrec ;;
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

    # ═══════════════════════════════════════════════════════════════════
    # STYLE MENU
    # ═══════════════════════════════════════════════════════════════════
    show_style_menu() {
      CHOICE=$(menu_cmd "Style" "󰸌  Theme\n  Background\n  Font")
      case "$CHOICE" in
        *Theme*) show_theme_list ;;
        *Background*) ${pkgs.libnotify}/bin/notify-send "Background" "To change background:\n1. Add image to assets/wallpapers\n2. Update omarchy.theme.assets.wallpaper in flake.nix\n3. Rebuild system" ;;
        *Font*) show_font_info ;;
        *) back_to show_main_menu ;;
      esac
    }

    # Informational Theme List
    show_theme_list() {
      # Show the list of available themes from Nix
      THEME=$(echo -e "${themeListStr}" | "$WALKER" --dmenu --width 400 --minheight 1 --maxheight 630 --placeholder "Available Themes...")
      
      # If they picked one, tell them how to set it
      if [[ -n "$THEME" ]]; then
        CLEAN_NAME=$(echo "$THEME" | sed 's/󰸌  //')
        ${pkgs.libnotify}/bin/notify-send "Set Theme: $CLEAN_NAME" "Edit flake.nix:\nomarchy.theme = \"$CLEAN_NAME\";\n\nThen run: sudo nixos-rebuild switch --flake ." -t 10000
      else
        back_to show_style_menu
      fi
    }

    show_font_info() {
      # Just list standard Nerd Fonts available in Omanix
      CHOICE=$(echo -e "  JetBrainsMono Nerd Font\n  FiraCode Nerd Font\n  Iosevka Nerd Font" | "$WALKER" --dmenu --width 400 --placeholder "Supported Fonts...")
      
      if [[ -n "$CHOICE" ]]; then
        CLEAN_NAME=$(echo "$CHOICE" | sed 's/  //')
        ${pkgs.libnotify}/bin/notify-send "Set Font: $CLEAN_NAME" "Edit flake.nix:\nomarchy.font = \"$CLEAN_NAME\";\n\nThen run: sudo nixos-rebuild switch --flake ." -t 10000
      else
        back_to show_style_menu
      fi
    }

    # ═══════════════════════════════════════════════════════════════════
    # SETUP MENU
    # ═══════════════════════════════════════════════════════════════════
    show_setup_menu() {
      CHOICE=$(menu_cmd "Setup" "  Audio\n  Wifi\n󰂯  Bluetooth\n  Hyprland\n󰒲  Hypridle\n  Hyprlock\n󰍜  Waybar\n󰌧  Walker")
      case "$CHOICE" in
        *Audio*) omarchy-launch-audio ;;
        *Wifi*) omarchy-launch-wifi ;;
        *Bluetooth*) omarchy-launch-bluetooth ;;
        # Configs are declarative in NixOS, show info instead of opening nvim
        *Hyprland*) show_config_info "Hyprland" "modules/home-manager/desktop/hyprland/" ;;
        *Hypridle*) show_config_info "Hypridle" "modules/home-manager/desktop/hypridle.nix" ;;
        *Hyprlock*) show_config_info "Hyprlock" "modules/home-manager/desktop/hyprlock.nix" ;;
        *Waybar*) show_config_info "Waybar" "modules/home-manager/ui/waybar.nix" ;;
        *Walker*) show_config_info "Walker" "modules/home-manager/ui/walker.nix" ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_config_info() {
      NAME="$1"
      PATH="$2"
      ${pkgs.libnotify}/bin/notify-send "Configuring $NAME" "This configuration is managed by Nix.\n\nEdit: $PATH\nin your Omanix repository." -t 8000
    }

    # ═══════════════════════════════════════════════════════════════════
    # SYSTEM MENU
    # ═══════════════════════════════════════════════════════════════════
    show_system_menu() {
      CHOICE=$(menu_cmd "System" "  Lock\n󱄄  Screensaver\n󰒲  Suspend\n󰜉  Relaunch\n󰜉  Restart\n  Shutdown")
      case "$CHOICE" in
        *Lock*) omarchy-lock-screen ;;
        *Screensaver*) ${pkgs.libnotify}/bin/notify-send "Screensaver" "Not yet implemented" ;;
        *Suspend*) systemctl suspend ;;
        *Relaunch*) hyprctl dispatch exit ;;
        *Restart*) omarchy-cmd-reboot ;;
        *Shutdown*) omarchy-cmd-shutdown ;;
        *) back_to show_main_menu ;;
      esac
    }

    # Entry point
    if [[ -n "$1" ]]; then
      go_to_menu "$1"
    else
      show_main_menu
    fi
  '';

  # Keybindings menu parser logic ported from upstream Bash
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
      
      # Use omarchy-launch-walker to ensure consistent styling
      output_keybindings | omarchy-launch-walker --dmenu -p 'Keybindings' --width 800 --height "$menu_height"
    fi
  '';

  # Walker Restart Script
  restartWalker = pkgs.writeShellScriptBin "omarchy-restart-walker" ''
    systemctl --user restart elephant.service
    sleep 0.5
    systemctl --user restart walker.service
    ${pkgs.libnotify}/bin/notify-send "Walker" "Services have been restarted"
  '';

  # Audio launcher
  launchAudio = pkgs.writeShellScriptBin "omarchy-launch-audio" ''
    ${pkgs.pavucontrol}/bin/pavucontrol &
  '';

  # Wifi launcher - Uses Impala TUI
  launchWifi = pkgs.writeShellScriptBin "omarchy-launch-wifi" ''
    # Using the TUI helper created in core.nix
    omarchy-launch-or-focus-tui impala
  '';

  # Bluetooth launcher - Uses BlueTUI
  launchBluetooth = pkgs.writeShellScriptBin "omarchy-launch-bluetooth" ''
    # Fallback to bluetui if available, similar to impala
    omarchy-launch-or-focus-tui bluetui
  '';

  # Toggle waybar
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
    keybindingsMenu
    restartWalker
    launchAudio
    launchWifi
    launchBluetooth
    toggleWaybar
    pkgs.networkmanagerapplet
    pkgs.libxkbcommon # Required for xkbcli
    pkgs.gawk # Required for awk
    pkgs.localsend # Required for Share > LocalSend
    pkgs.impala # Required for Wifi TUI
    pkgs.bluetui # Required for Bluetooth TUI
  ];
}
