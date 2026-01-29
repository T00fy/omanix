{ pkgs, inputs, ... }:
let
  walkerPkg = inputs.walker.packages.${pkgs.system}.default;

  # The Main Omarchy Menu - matching upstream structure
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
      CHOICE=$(menu_cmd "Go" "󰀻  Apps\n  Learn\n󱓞  Trigger\n  Style\n  Setup\n  System")
      go_to_menu "$CHOICE"
    }

    go_to_menu() {
      case "''${1,,}" in
        *apps*) "$WALKER" ;;
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
      CHOICE=$(menu_cmd "Learn" "  Keybindings\n  Omarchy\n  Hyprland\n󰣇  Arch\n  Neovim\n󱆃  Bash")
      case "$CHOICE" in
        *Keybindings*) omarchy-menu-keybindings ;;
        *Omarchy*) xdg-open "https://omarchy.org" ;;
        *Hyprland*) xdg-open "https://wiki.hyprland.org" ;;
        *Arch*) xdg-open "https://wiki.archlinux.org" ;;
        *Neovim*) xdg-open "https://neovim.io/doc/" ;;
        *Bash*) xdg-open "https://www.gnu.org/software/bash/manual/" ;;
        *) back_to show_main_menu ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # TRIGGER MENU
    # ═══════════════════════════════════════════════════════════════════
    show_trigger_menu() {
      CHOICE=$(menu_cmd "Trigger" "  Capture\n  Share\n󰃉  Color Picker")
      case "$CHOICE" in
        *Capture*) show_capture_menu ;;
        *Share*) show_share_menu ;;
        *Color*) ${pkgs.hyprpicker}/bin/hyprpicker -a ;;
        *) back_to show_main_menu ;;
      esac
    }

    show_capture_menu() {
      CHOICE=$(menu_cmd "Capture" "  Screenshot\n  Screenrecord")
      case "$CHOICE" in
        *Screenshot*) show_screenshot_menu ;;
        *Screenrecord*) show_screenrecord_menu ;;
        *) back_to show_trigger_menu ;;
      esac
    }

    show_screenshot_menu() {
      CHOICE=$(menu_cmd "Screenshot" "  Smart Select\n󰍹  Full Screen\n  Region\n󱂬  Window")
      case "$CHOICE" in
        *Smart*) omarchy-cmd-screenshot smart file ;;
        *Full*) omarchy-cmd-screenshot fullscreen file ;;
        *Region*) omarchy-cmd-screenshot region file ;;
        *Window*) omarchy-cmd-screenshot windows file ;;
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
        *LocalSend*) localsend ;;
        *) back_to show_trigger_menu ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # STYLE MENU
    # ═══════════════════════════════════════════════════════════════════
    show_style_menu() {
      CHOICE=$(menu_cmd "Style" "  Background\n󰸌  Theme\n  Font")
      case "$CHOICE" in
        *Background*) omarchy-theme-bg-next 2>/dev/null || ${pkgs.libnotify}/bin/notify-send "Background" "Cycle wallpaper not yet implemented" ;;
        *Theme*) ${pkgs.libnotify}/bin/notify-send "NixOS Theme" "Edit omarchy.theme in your flake.nix to change theme" ;;
        *Font*) ${pkgs.libnotify}/bin/notify-send "NixOS Font" "Edit omarchy.font in your flake.nix to change font" ;;
        *) back_to show_main_menu ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # SETUP MENU
    # ═══════════════════════════════════════════════════════════════════
    show_setup_menu() {
      CHOICE=$(menu_cmd "Setup" "  Audio\n  Wifi\n󰂯  Bluetooth\n  Hyprland\n  Hypridle\n  Hyprlock\n󰍜  Waybar\n󰌧  Walker")
      case "$CHOICE" in
        *Audio*) omarchy-launch-audio ;;
        *Wifi*) omarchy-launch-wifi ;;
        *Bluetooth*) omarchy-launch-bluetooth ;;
        *Hyprland*) ''${EDITOR:-nvim} ~/.config/hypr ;;
        *Hypridle*) ''${EDITOR:-nvim} ~/.config/hypr/hypridle.conf ;;
        *Hyprlock*) ''${EDITOR:-nvim} ~/.config/hypr/hyprlock.conf ;;
        *Waybar*) ''${EDITOR:-nvim} ~/.config/waybar ;;
        *Walker*) ''${EDITOR:-nvim} ~/.config/walker ;;
        *) back_to show_main_menu ;;
      esac
    }

    # ═══════════════════════════════════════════════════════════════════
    # SYSTEM MENU
    # ═══════════════════════════════════════════════════════════════════
    show_system_menu() {
      CHOICE=$(menu_cmd "System" "  Lock\n󱄄  Screensaver\n󰤄  Suspend\n  Relaunch\n󰜉  Restart\n󰐥  Shutdown")
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

  # Keybindings menu helper
  keybindingsMenu = pkgs.writeShellScriptBin "omarchy-menu-keybindings" ''
    ${pkgs.libnotify}/bin/notify-send "Keybindings" "
    Super+Space: App Launcher
    Super+Alt+Space: Omarchy Menu
    Super+Return: Terminal
    Super+Shift+B: Browser
    Super+Shift+F: File Manager
    Super+Shift+N: Neovim
    Super+W: Close Window
    Super+F: Fullscreen
    Super+T: Toggle Floating
    Super+1-0: Switch Workspace
    Super+Shift+1-0: Move to Workspace
    Print: Screenshot
    "
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

  # Wifi launcher  
  launchWifi = pkgs.writeShellScriptBin "omarchy-launch-wifi" ''
    ${pkgs.networkmanagerapplet}/bin/nm-connection-editor &
  '';

  # Bluetooth launcher
  launchBluetooth = pkgs.writeShellScriptBin "omarchy-launch-bluetooth" ''
    ${pkgs.blueman}/bin/blueman-manager &
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
  ];
}
