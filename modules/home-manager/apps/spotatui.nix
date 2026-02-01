{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.spotatui;
  theme = config.omanix.activeTheme;
in
{
  options.omanix.spotatui = {
    enable = lib.mkEnableOption "Spotatui - Spotify TUI client" // {
      default = false;
    };

    enableGlobalSongCount = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Contribute to the anonymous global song counter.
        This is completely anonymous - no personal information is collected.
      '';
    };

    enableDiscordRpc = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Discord Rich Presence integration.";
    };

    seekMilliseconds = lib.mkOption {
      type = lib.types.int;
      default = 5000;
      description = "Milliseconds to seek when using seek keybindings.";
    };

    volumeIncrement = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Volume increment/decrement step.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotatui ];

    # Generate themed config.yml
    # Note: client.yml (credentials) is NOT managed here - it's created interactively
    # by spotatui on first run via OAuth flow
    # xdg.configFile."spotatui/config.yml".text = ''
    #   # Omanix-generated spotatui configuration
    #   # Note: Authentication is handled interactively on first run.
    #   # Run 'spotatui' and follow the prompts to connect your Spotify account.
    #
    #   theme:
    #     active: "${theme.colors.accent}"
    #     banner: "${theme.colors.accent}"
    #     error_border: "${theme.colors.color1}"
    #     error_text: "${theme.colors.color9}"
    #     hint: "${theme.colors.color3}"
    #     hovered: "${theme.colors.color5}"
    #     inactive: "${theme.colors.color8}"
    #     playbar_background: "${theme.colors.background}"
    #     playbar_progress: "${theme.colors.accent}"
    #     playbar_progress_text: "${theme.colors.accent}"
    #     playbar_text: "${theme.colors.foreground}"
    #     selected: "${theme.colors.accent}"
    #     text: "${theme.colors.foreground}"
    #     header: "${theme.colors.foreground}"
    #
    #   behavior:
    #     seek_milliseconds: ${toString cfg.seekMilliseconds}
    #     volume_increment: ${toString cfg.volumeIncrement}
    #     tick_rate_milliseconds: 250
    #     enable_text_emphasis: true
    #     show_loading_indicator: true
    #     enforce_wide_search_bar: false
    #     enable_global_song_count: ${lib.boolToString cfg.enableGlobalSongCount}
    #     enable_discord_rpc: ${lib.boolToString cfg.enableDiscordRpc}
    #     liked_icon: "♥"
    #     shuffle_icon: "🔀"
    #     repeat_track_icon: "🔂"
    #     repeat_context_icon: "🔁"
    #     playing_icon: "▶"
    #     paused_icon: "⏸"
    #     set_window_title: true
    # '';
  };
}
