{ config, lib, ... }:
let
  cfg = config.omanix.hyprland;
in
{
  options.omanix.hyprland = {
    extraWindowRules = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = ''
        Extra window rules appended to the Omanix defaults.
        Use attrset format for Lua config:
          { match = { class = "^(my-app)$"; }; float = true; }
      '';
    };

    extraLayerRules = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [ ];
      description = ''
        Extra layer rules appended to the Omanix defaults.
        Use attrset format for Lua config:
          { match = { namespace = "my-layer"; }; blur = true; }
      '';
    };
  };

  config = {
    wayland.windowManager.hyprland.settings = {
      window_rule =
        [
          # ─────────────────────────────────────────────────────────────────
          # Global defaults
          # ─────────────────────────────────────────────────────────────────
          {
            match = { class = ".*"; };
            suppress_event = "maximize";
          }
          {
            match = { class = ".*"; };
            opacity = "0.97 0.9";
          }

          # Fix XWayland dragging issues
          {
            name = "fix-xwayland-drags";
            match = {
              class = "^$";
              title = "^$";
              xwayland = true;
              float = true;
              fullscreen = false;
              pin = false;
            };
            no_focus = true;
          }

          # ─────────────────────────────────────────────────────────────────
          # Password Managers
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "^(1[p|P]assword)$"; }; no_screen_share = true; }
          { match = { class = "^(1[p|P]assword)$"; }; tag = "+floating-window"; }
          { match = { class = "^(Bitwarden)$"; }; no_screen_share = true; }
          { match = { class = "^(Bitwarden)$"; }; tag = "+floating-window"; }

          # ─────────────────────────────────────────────────────────────────
          # Browsers
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)"; }; tag = "+chromium-based-browser"; }
          { match = { class = "([fF]irefox|zen|librewolf)"; }; tag = "+firefox-based-browser"; }
          { match = { tag = "chromium-based-browser"; }; tile = true; }
          { match = { tag = "chromium-based-browser"; }; opacity = "1.0 0.97"; }
          { match = { tag = "firefox-based-browser"; }; opacity = "1.0 0.97"; }
          {
            match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)"; };
            opacity = "1.0 1.0";
          }

          # ─────────────────────────────────────────────────────────────────
          # Terminals
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "(Alacritty|kitty|com.mitchellh.ghostty|foot)"; }; tag = "+terminal"; }

          # ─────────────────────────────────────────────────────────────────
          # JetBrains IDEs
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "^(jetbrains-.*)$"; title = "^(splash)$"; float = true; }; tag = "+jetbrains-splash"; }
          { match = { tag = "jetbrains-splash"; }; center = true; }
          { match = { tag = "jetbrains-splash"; }; no_focus = true; }
          { match = { tag = "jetbrains-splash"; }; border_size = 0; }

          { match = { class = "^(jetbrains-.*)$"; title = "^()$"; float = true; }; tag = "+jetbrains-popup"; }
          { match = { tag = "jetbrains-popup"; }; center = true; }
          { match = { tag = "jetbrains-popup"; }; stay_focused = true; }
          { match = { tag = "jetbrains-popup"; }; border_size = 0; }
          { match = { tag = "jetbrains-popup"; }; min_size = "monitor_w*0.5 monitor_h*0.5"; }

          { match = { class = "^(jetbrains-.*)$"; title = "^(win.*)$"; float = true; }; no_initial_focus = true; }
          { match = { class = "^(jetbrains-.*)$"; }; no_follow_mouse = true; }

          # ─────────────────────────────────────────────────────────────────
          # DaVinci Resolve
          # ─────────────────────────────────────────────────────────────────
          { match = { class = ".*[Rr]esolve.*"; float = true; }; stay_focused = true; }

          # ─────────────────────────────────────────────────────────────────
          # Picture-in-Picture
          # ─────────────────────────────────────────────────────────────────
          { match = { title = "(Picture.?in.?[Pp]icture)"; }; tag = "+pip"; }
          { match = { tag = "pip"; }; float = true; }
          { match = { tag = "pip"; }; pin = true; }
          { match = { tag = "pip"; }; size = "600 338"; }
          { match = { tag = "pip"; }; keep_aspect_ratio = true; }
          { match = { tag = "pip"; }; border_size = 0; }
          { match = { tag = "pip"; }; opacity = "1.0 1.0"; }
          { match = { tag = "pip"; }; move = "monitor_w-window_w-40 monitor_h*0.04"; }

          # ─────────────────────────────────────────────────────────────────
          # Steam
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "steam"; }; float = true; }
          { match = { class = "steam"; title = "Steam"; }; center = true; }
          { match = { class = "steam"; }; opacity = "1.0 1.0"; }
          { match = { class = "steam"; title = "Steam"; }; size = "1100 700"; }
          { match = { class = "steam"; title = "Friends List"; }; size = "460 800"; }
          { match = { class = "steam"; }; idle_inhibit = "fullscreen"; }

          # ─────────────────────────────────────────────────────────────────
          # RetroArch
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "com.libretro.RetroArch"; }; fullscreen = true; }
          { match = { class = "com.libretro.RetroArch"; }; opacity = "1.0 1.0"; }
          { match = { class = "com.libretro.RetroArch"; }; idle_inhibit = "fullscreen"; }

          # ─────────────────────────────────────────────────────────────────
          # QEMU
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "qemu"; }; opacity = "1.0 1.0"; }

          # ─────────────────────────────────────────────────────────────────
          # LocalSend
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "(Share|localsend)"; }; float = true; }
          { match = { class = "(Share|localsend)"; }; center = true; }

          # ─────────────────────────────────────────────────────────────────
          # Webcam Overlay
          # ─────────────────────────────────────────────────────────────────
          { match = { title = "WebcamOverlay"; }; float = true; }
          { match = { title = "WebcamOverlay"; }; pin = true; }
          { match = { title = "WebcamOverlay"; }; no_initial_focus = true; }
          { match = { title = "WebcamOverlay"; }; no_dim = true; }
          { match = { title = "WebcamOverlay"; }; move = "monitor_w-window_w-40 monitor_h-window_h-40"; }

          # ─────────────────────────────────────────────────────────────────
          # Screenshot Editor (Satty)
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "^(com.gabm.satty)$"; }; float = true; }
          { match = { class = "^(com.gabm.satty)$"; }; center = true; }
          { match = { class = "^(com.gabm.satty)$"; }; size = "80% 80%"; }
          { match = { class = "^(com.gabm.satty)$"; }; stay_focused = true; }

          # ─────────────────────────────────────────────────────────────────
          # System Floating Windows
          # ─────────────────────────────────────────────────────────────────
          { match = { tag = "floating-window"; }; float = true; }
          { match = { tag = "floating-window"; }; center = true; }
          { match = { tag = "floating-window"; }; size = "875 600"; }

          { match = { class = "(org.omanix.bluetui|org.omanix.impala|org.omanix.wiremix|org.omanix.btop|org.omanix.terminal|org.omanix.bash|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv)"; }; tag = "+floating-window"; }
          { match = { class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)"; title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)$"; }; tag = "+floating-window"; }
          { match = { class = "org.gnome.Calculator"; }; float = true; }

          # No transparency on media windows
          {
            match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$"; };
            opacity = "1.0 1.0";
          }
          # Popped window rounding
          { match = { tag = "pop"; }; rounding = 8; }

          # Prevent idle while open
          { match = { tag = "noidle"; }; idle_inhibit = "always"; }

          # ─────────────────────────────────────────────────────────────────
          # Misc floating utilities
          # ─────────────────────────────────────────────────────────────────
          { match = { class = "^(org.pulseaudio.pavucontrol)$"; }; float = true; }
          { match = { class = "^(org.pulseaudio.pavucontrol)$"; }; center = true; }
          { match = { class = "^(org.pulseaudio.pavucontrol)$"; }; size = "875 600"; }
          { match = { class = "^(xdg-desktop-portal-gtk)$"; }; float = true; }
        ]
        ++ cfg.extraWindowRules;

      # ═══════════════════════════════════════════════════════════════════
      # LAYER RULES
      # ═══════════════════════════════════════════════════════════════════
      layer_rule =
        [
          { match = { namespace = "selection"; }; no_anim = true; }
          { match = { namespace = "^(selection)$"; }; no_anim = true; }
          { match = { namespace = "^(wayfreeze)$"; }; no_anim = true; }
          { match = { namespace = "wofi"; }; blur = true; }
          { match = { namespace = "notifications"; }; blur = true; }
          { match = { namespace = "wofi"; }; ignore_alpha = 0.5; }
          { match = { namespace = "notifications"; }; ignore_alpha = 0.5; }
        ]
        ++ cfg.extraLayerRules;
    };
  };
}
