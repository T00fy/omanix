{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    # ═══════════════════════════════════════════════════════════════════
    # WINDOW RULES - Omarchy Parity
    # ═══════════════════════════════════════════════════════════════════

    windowrule = [
      # ─────────────────────────────────────────────────────────────────
      # Global defaults
      # ─────────────────────────────────────────────────────────────────
      "suppress_event maximize, match:class .*"
      "opacity 0.97 0.9, match:class .*"

      # Fix XWayland dragging issues
      "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0"

      # ─────────────────────────────────────────────────────────────────
      # Screensaver (TTE in fullscreen terminal)
      # ─────────────────────────────────────────────────────────────────
      "fullscreen on, match:class ^(org\\.omanix\\.screensaver)$"
      "float on, match:class ^(org\\.omanix\\.screensaver)$"
      "opacity 1 1, match:class ^(org\\.omanix\\.screensaver)$"
      "no_blur on, match:class ^(org\\.omanix\\.screensaver)$"
      "no_shadow on, match:class ^(org\\.omanix\\.screensaver)$"
      "border_size 0, match:class ^(org\\.omanix\\.screensaver)$"
      "no_focus on, match:class ^(org\\.omanix\\.screensaver)$"
      "suppress_event activate, match:class ^(org\\.omanix\\.screensaver)$"

      # ─────────────────────────────────────────────────────────────────
      # Password Managers
      # ─────────────────────────────────────────────────────────────────
      "no_screen_share on, match:class ^(1[p|P]assword)$"
      "tag +floating-window, match:class ^(1[p|P]assword)$"
      "no_screen_share on, match:class ^(Bitwarden)$"
      "tag +floating-window, match:class ^(Bitwarden)$"

      # ─────────────────────────────────────────────────────────────────
      # Browsers
      # ─────────────────────────────────────────────────────────────────
      "tag +chromium-based-browser, match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)"
      "tag +firefox-based-browser, match:class ([fF]irefox|zen|librewolf)"
      "tile on, match:tag chromium-based-browser"
      "opacity 1 0.97, match:tag chromium-based-browser"
      "opacity 1 0.97, match:tag firefox-based-browser"
      "opacity 1.0 1.0, match:initial_title ((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)"

      # ─────────────────────────────────────────────────────────────────
      # Terminals
      # ─────────────────────────────────────────────────────────────────
      "tag +terminal, match:class (Alacritty|kitty|com.mitchellh.ghostty)"

      # Spotatui - Spotify TUI (larger window for better experience)
      "tag +floating-window, match:class ^(org\\.omanix\\.spotatui)$"
      "size 1000 700, match:class ^(org\\.omanix\\.spotatui)$"

      # ─────────────────────────────────────────────────────────────────
      # JetBrains IDEs
      # ─────────────────────────────────────────────────────────────────
      "tag +jetbrains-splash, match:class ^(jetbrains-.*)$, match:title ^(splash)$, match:float 1"
      "center on, match:tag jetbrains-splash"
      "no_focus on, match:tag jetbrains-splash"
      "border_size 0, match:tag jetbrains-splash"
      "tag +jetbrains, match:class ^(jetbrains-.*), match:title ^()$, match:float 1"
      "center on, match:tag jetbrains"
      "stay_focused on, match:tag jetbrains"
      "border_size 0, match:tag jetbrains"
      "min_size (monitor_w*0.5) (monitor_h*0.5), match:class ^(jetbrains-.*), match:title ^()$, match:float 1"
      "no_initial_focus on, match:class ^(jetbrains-.*)$, match:title ^(win.*)$, match:float 1"
      "no_follow_mouse on, match:class ^(jetbrains-.*)$"

      # ─────────────────────────────────────────────────────────────────
      # DaVinci Resolve
      # ─────────────────────────────────────────────────────────────────
      "stay_focused on, match:class .*[Rr]esolve.*, match:float 1"

      # ─────────────────────────────────────────────────────────────────
      # Picture-in-Picture
      # ─────────────────────────────────────────────────────────────────
      "tag +pip, match:title (Picture.?in.?[Pp]icture)"
      "float on, match:tag pip"
      "pin on, match:tag pip"
      "size 600 338, match:tag pip"
      "keep_aspect_ratio on, match:tag pip"
      "border_size 0, match:tag pip"
      "opacity 1 1, match:tag pip"
      "move (monitor_w-window_w-40) (monitor_h*0.04), match:tag pip"

      # ─────────────────────────────────────────────────────────────────
      # Steam
      # ─────────────────────────────────────────────────────────────────
      "float on, match:class steam"
      "center on, match:class steam, match:title Steam"
      "opacity 1 1, match:class steam"
      "size 1100 700, match:class steam, match:title Steam"
      "size 460 800, match:class steam, match:title Friends List"
      "idle_inhibit fullscreen, match:class steam"

      # ─────────────────────────────────────────────────────────────────
      # RetroArch
      # ─────────────────────────────────────────────────────────────────
      "fullscreen on, match:class com.libretro.RetroArch"
      "opacity 1 1, match:class com.libretro.RetroArch"
      "idle_inhibit fullscreen, match:class com.libretro.RetroArch"

      # ─────────────────────────────────────────────────────────────────
      # QEMU
      # ─────────────────────────────────────────────────────────────────
      "opacity 1 1, match:class qemu"

      # ─────────────────────────────────────────────────────────────────
      # LocalSend
      # ─────────────────────────────────────────────────────────────────
      "float on, match:class (Share|localsend)"
      "center on, match:class (Share|localsend)"

      # ─────────────────────────────────────────────────────────────────
      # Webcam Overlay
      # ─────────────────────────────────────────────────────────────────
      "float on, match:title WebcamOverlay"
      "pin on, match:title WebcamOverlay"
      "no_initial_focus on, match:title WebcamOverlay"
      "no_dim on, match:title WebcamOverlay"
      "move (monitor_w-window_w-40) (monitor_h-window_h-40), match:title WebcamOverlay"

      # ─────────────────────────────────────────────────────────────────
      # Screenshot Editor (Satty)
      # ─────────────────────────────────────────────────────────────────
      "float on, match:class ^(com.gabm.satty)$"
      "center on, match:class ^(com.gabm.satty)$"
      "size 80% 80%, match:class ^(com.gabm.satty)$"
      "stay_focused on, match:class ^(com.gabm.satty)$"

      # ─────────────────────────────────────────────────────────────────
      # System Floating Windows
      # ─────────────────────────────────────────────────────────────────
      "float on, match:tag floating-window"
      "center on, match:tag floating-window"
      "size 875 600, match:tag floating-window"

      "tag +floating-window, match:class (org.omanix.bluetui|org.omanix.impala|org.omanix.wiremix|org.omanix.btop|org.omanix.terminal|org.omanix.bash|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv)"
      "tag +floating-window, match:class (xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus), match:title ^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)$"
      "float on, match:class org.gnome.Calculator"

      # No transparency on media windows
      "opacity 1 1, match:class ^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"

      # Popped window rounding
      "rounding 8, match:tag pop"

      # Prevent idle while open
      "idle_inhibit always, match:tag noidle"

      # ─────────────────────────────────────────────────────────────────
      # Misc floating utilities
      # ─────────────────────────────────────────────────────────────────
      "float on, match:class ^(org.pulseaudio.pavucontrol)$"
      "center on, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 875 600, match:class ^(org.pulseaudio.pavucontrol)$"
      "float on, match:class ^(xdg-desktop-portal-gtk)$"
    ];

    # ═══════════════════════════════════════════════════════════════════
    # LAYER RULES
    # ═══════════════════════════════════════════════════════════════════
    layerrule = [
      "no_anim on, match:namespace selection"
      "no_anim on, match:namespace ^(selection)$"
      "no_anim on, match:namespace ^(wayfreeze)$"
      "no_anim on, match:namespace walker"
      "blur on, match:namespace waybar"
      "blur on, match:namespace wofi"
      "blur on, match:namespace notifications"
      "ignore_alpha 0.5, match:namespace waybar"
      "ignore_alpha 0.5, match:namespace wofi"
      "ignore_alpha 0.5, match:namespace notifications"
    ];
  };
}
