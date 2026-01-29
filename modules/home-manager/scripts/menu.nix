{ pkgs, inputs, ... }:
let
  # Get the walker package from the flake input
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;

  # 1. The Main Omarchy Menu Router
  menu = pkgs.writeShellScriptBin "omarchy-menu" ''
    # Use explicit path to walker from Nix store
    WALKER="${walkerPkg}/bin/walker"

    # Helper to show a walker dmenu with Omarchy styling
    menu_cmd() {
      local placeholder="$1"
      local options="$2"
      echo -e "$options" | "$WALKER" --dmenu --width 295 --minheight 1 --maxheight 630 --placeholder "$placeholder…"
    }

    show_main_menu() {
      CHOICE=$(menu_cmd "Go" "󰀻  Apps\n󱓞  Trigger\n  Style\n  Setup\n  System")
      go_to_menu "$CHOICE"
    }

    go_to_menu() {
      case "''${1,,}" in
        *apps*) "$WALKER" -p "Launch…" ;;
        *trigger*) show_trigger_menu ;;
        *system*) show_system_menu ;;
        *style*) show_style_menu ;;
        *setup*) show_setup_menu ;;
        *) ;; # Exit if cancelled/no match
      esac
    }

    show_system_menu() {
      CHOICE=$(menu_cmd "System" "  Lock\n󱄄  Screensaver\n󰐥  Shutdown\n󰜉  Restart\n󰒲  Suspend")
      case "$CHOICE" in
        *Lock*) omarchy-lock-screen ;;
        *Screensaver*) omarchy-launch-screensaver force ;;
        *Shutdown*) omarchy-cmd-shutdown ;;
        *Restart*) omarchy-cmd-reboot ;;
        *Suspend*) systemctl suspend ;;
        *) show_main_menu ;;
      esac
    }

    show_trigger_menu() {
      CHOICE=$(menu_cmd "Trigger" "  Capture\n  Share\n󰃉  Color Picker")
      case "$CHOICE" in
        *Capture*) show_capture_menu ;;
        *Share*) omarchy-menu share ;;
        *Color*) ${pkgs.hyprpicker}/bin/hyprpicker -a ;;
        *) show_main_menu ;;
      esac
    }

    show_capture_menu() {
      CHOICE=$(menu_cmd "Capture" "  Screenshot\n  Screenrecord")
      case "$CHOICE" in
        *Screenshot*) omarchy-cmd-screenshot smart file ;;
        *Screenrecord*) omarchy-menu screenrecord ;;
        *) show_trigger_menu ;;
      esac
    }

    show_style_menu() {
       CHOICE=$(menu_cmd "Style" "  Background\n  Font")
       case "$CHOICE" in
         *Background*) omarchy-theme-bg-next ;;
         *) show_main_menu ;;
       esac
    }

    show_setup_menu() {
       CHOICE=$(menu_cmd "Setup" "  Audio\n  Wifi\n󰂯  Bluetooth")
       case "$CHOICE" in
         *Audio*) omarchy-launch-audio ;;
         *Wifi*) omarchy-launch-wifi ;;
         *Bluetooth*) omarchy-launch-bluetooth ;;
         *) show_main_menu ;;
       esac
    }

    # Entry point: handles direct jumps (e.g. 'omarchy-menu system')
    if [[ -n "$1" ]]; then
      go_to_menu "$1"
    else
      show_main_menu
    fi
  '';

  # 2. Walker Restart Script
  restartWalker = pkgs.writeShellScriptBin "omarchy-restart-walker" ''
    # Restart the data provider
    systemctl --user restart elephant.service
    # Restart the UI
    systemctl --user restart walker.service

    ${pkgs.libnotify}/bin/notify-send "Walker" "Services have been restarted"
  '';

in
{
  home.packages = [
    menu
    restartWalker
  ];
}
