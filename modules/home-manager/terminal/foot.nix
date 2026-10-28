{ config, lib, pkgs, ... }:
let
  cfg = config.omanix.terminal;
  theme = config.omanix.activeTheme;
  inherit (theme) colors;

  # Single source of truth for the per-scale font size, so the normal
  # omanix.monitor.scale rendering and the default scaledFontSize (used by
  # omanix-scale, the runtime Moonlight UI-scale toggle) can't drift apart.
  mkFontSize = scale: if scale == "1" then 13 else 10;

  scale = config.omanix.monitor.scale;
  fontSize = mkFontSize scale;
  strip = c: lib.removePrefix "#" c;
in
{
  options.omanix.terminal.scaledFontSize = lib.mkOption {
    type = lib.types.int;
    default = mkFontSize "2";
    description = ''
      Font size (pt) new foot windows use while omanix-scale is active (see
      pkgs/omanix-scripts/src/omanix-scale.sh), e.g. during a scaled Moonlight
      session. Applied via `foot -o main.font=...:size=N` at launch time by
      the omanix-term wrapper.

      NOTE: this only affects NEW foot windows opened while scaling is
      active — foot has no signal/IPC to live-resize the font of an
      already-open window (only SIGUSR1/2 for switching the color theme).
      Existing windows are unaffected either direction; use foot's own
      Ctrl+-/Ctrl++ bindings for those, as today. Revisit this if foot ever
      gains a live font-resize API (or omanix builds one, e.g. a wrapper
      around footclient).
    '';
  };

  options.omanix.terminal.scaledFontMarkers = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "omanix-scale-active" ];
    example = [
      "omanix-scale-active"
      "my-streaming-active"
    ];
    description = ''
      Marker files in `$XDG_RUNTIME_DIR` that make new foot windows use
      `scaledFontSize`. The default is omanix-scale's own; add the marker of
      any other script of yours that renders the desktop at 2x while it runs.
    '';
  };

  config = lib.mkIf (cfg.emulator == "foot") {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          shell = "${pkgs.zsh}/bin/zsh";
          font = "${config.omanix.font}:size=${toString fontSize}";
          pad = "14x14";
          dpi-aware = "no";
        };
        tweak = {
          grapheme-width-method = "max";
        };
        cursor = {
          style = "block";
          blink = "no";
        };
        mouse = {
          hide-when-typing = "yes";
        };
        scrollback = {
          multiplier = toString (builtins.floor cfg.mouseScrollMultiplier);
        };
        colors-dark = {
          background = strip colors.background;
          foreground = strip colors.foreground;
          cursor = "${strip colors.background} ${strip colors.cursor}";
          regular0 = strip colors.color0;
          regular1 = strip colors.color1;
          regular2 = strip colors.color2;
          regular3 = strip colors.color3;
          regular4 = strip colors.color4;
          regular5 = strip colors.color5;
          regular6 = strip colors.color6;
          regular7 = strip colors.color7;
          bright0 = strip colors.color8;
          bright1 = strip colors.color9;
          bright2 = strip colors.color10;
          bright3 = strip colors.color11;
          bright4 = strip colors.color12;
          bright5 = strip colors.color13;
          bright6 = strip colors.color14;
          bright7 = strip colors.color15;
          selection-foreground = strip colors.selection_foreground;
          selection-background = strip colors.selection_background;
        };
      };
    };
  };
}
