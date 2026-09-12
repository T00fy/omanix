{
  config,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.tmux;
  colors = config.omanix.activeTheme.colors;
in
{
  options.omanix.apps.tmux = {
    enable = lib.mkEnableOption "tmux with AI dev layouts" // { default = true; };

    aiCommand = lib.mkOption {
      type = lib.types.str;
      default = "claude";
      description = "AI CLI command used in layout aliases (e.g. claude, opencode)";
    };

    hyprlandBinding = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add Super+Alt+Return keybinding to launch/attach tmux";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      prefix = "C-Space";
      mouse = true;
      baseIndex = 1;
      historyLimit = 50000;
      escapeTime = 0;
      terminal = "tmux-256color";
      extraConfig = ''
        set -g prefix2 C-b
        bind C-Space send-prefix

        # Reload config
        bind q source-file ~/.config/tmux/tmux.conf \; display "Configuration reloaded"

        # Vi mode for copy
        setw -g mode-keys vi
        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi y send -X copy-selection-and-cancel

        # Pane controls
        bind h split-window -v -c "#{pane_current_path}"
        bind v split-window -h -c "#{pane_current_path}"
        bind x kill-pane

        bind -n C-M-Left select-pane -L
        bind -n C-M-Right select-pane -R
        bind -n C-M-Up select-pane -U
        bind -n C-M-Down select-pane -D

        bind -n C-M-S-Left resize-pane -L 5
        bind -n C-M-S-Down resize-pane -D 5
        bind -n C-M-S-Up resize-pane -U 5
        bind -n C-M-S-Right resize-pane -R 5

        # Window navigation
        bind r command-prompt -I "#W" "rename-window -- '%%'"
        bind c new-window -c "#{pane_current_path}"
        bind k kill-window

        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5
        bind -n M-6 select-window -t 6
        bind -n M-7 select-window -t 7
        bind -n M-8 select-window -t 8
        bind -n M-9 select-window -t 9

        bind -n M-Left select-window -t -1
        bind -n M-Right select-window -t +1
        bind -n M-S-Left swap-window -t -1 \; select-window -t -1
        bind -n M-S-Right swap-window -t +1 \; select-window -t +1

        # Session controls
        bind R command-prompt -I "#S" "rename-session -- '%%'"
        bind C new-session -c "#{pane_current_path}"
        bind K kill-session
        bind P switch-client -p
        bind N switch-client -n

        bind -n M-Up switch-client -p
        bind -n M-Down switch-client -n

        # General
        set -ag terminal-overrides ",*:RGB"
        set -g renumber-windows on
        set -g focus-events on
        set -g set-clipboard on
        set -g allow-passthrough on
        setw -g aggressive-resize on
        set -g detach-on-destroy off

        # Status bar
        set -g status-position top
        set -g status-interval 5
        set -g status-left-length 30
        set -g status-right-length 50
        set -g window-status-separator ""
        set -gw automatic-rename on
        set -gw automatic-rename-format '#{b:pane_current_path}'

        # Theme (resolves through terminal palette — inherits active Omanix theme)
        set -g status-style "bg=default,fg=default"
        set -g status-left "#[fg=black,bg=blue,bold] #S #[bg=default] "
        set -g status-right "#[fg=blue]#{?pane_in_mode,COPY ,}#{?client_prefix,PREFIX ,}#{?window_zoomed_flag,ZOOM ,}#[fg=brightblack]#h "
        set -g window-status-format "#[fg=brightblack] #I:#W "
        set -g window-status-current-format "#[fg=blue,bold] #I:#W "
        set -g pane-border-style "fg=brightblack"
        set -g pane-active-border-style "fg=blue"
        set -g message-style "bg=default,fg=blue"
        set -g message-command-style "bg=default,fg=blue"
        set -g mode-style "bg=blue,fg=black"
        setw -g clock-mode-colour blue

        # Declarative palette baseline: pin the editor surface + cursor to the
        # active theme's hex, so a rebuild sets the declared theme. The live
        # switch (omanix-theme-set-tmux) sets the same options on a running
        # server; both must agree.
        set -g window-style "fg=${colors.foreground},bg=${colors.background}"
        set -g window-active-style "fg=${colors.foreground},bg=${colors.background}"
        set -g cursor-colour "${colors.cursor}"
      '';
    };

    programs.zsh = {
      shellAliases = {
        t = "tmux attach || tmux new -s Work";
        ic = "tdl ${cfg.aiCommand}";
      };

      initContent = lib.mkAfter ''
        # Create a Tmux Dev Layout with editor, ai, and terminal
        # Usage: tdl <ai_command> [<second_ai_command>]
        tdl() {
          [[ -z $1 ]] && { echo "Usage: tdl <ai_command> [<second_ai_command>]"; return 1; }
          [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

          local current_dir="''${PWD}"
          local editor_pane ai_pane ai2_pane
          local ai="$1"
          local ai2="$2"

          editor_pane="$TMUX_PANE"
          tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"
          tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"
          ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

          if [[ -n $ai2 ]]; then
            ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
            tmux send-keys -t "$ai2_pane" "$ai2" C-m
          fi

          tmux send-keys -t "$ai_pane" "$ai" C-m
          tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
          tmux select-pane -t "$editor_pane"
        }

        # Create multiple tdl windows, one per subdirectory
        # Usage: tdlm <ai_command> [<second_ai_command>]
        tdlm() {
          [[ -z $1 ]] && { echo "Usage: tdlm <ai_command> [<second_ai_command>]"; return 1; }
          [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

          local ai="$1"
          local ai2="$2"
          local base_dir="$PWD"
          local first=true

          tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

          for dir in "$base_dir"/*/; do
            [[ -d $dir ]] || continue
            local dirpath="''${dir%/}"

            if $first; then
              tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
              first=false
            else
              local pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
              tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
            fi
          done
        }

        # Create a multi-pane swarm layout with the same command in each pane
        # Usage: tsl <pane_count> <command>
        tsl() {
          [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
          [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

          local count="$1"
          local cmd="$2"
          local current_dir="''${PWD}"
          local -a panes

          tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"
          panes+=("$TMUX_PANE")

          while (( ''${#panes[@]} < count )); do
            local new_pane
            local split_target="''${panes[-1]}"
            new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}')
            panes+=("$new_pane")
            tmux select-layout -t "''${panes[0]}" tiled
          done

          for pane in "''${panes[@]}"; do
            tmux send-keys -t "$pane" "$cmd" C-m
          done

          tmux select-pane -t "''${panes[0]}"
        }
      '';
    };

    omanix.hyprland.extraBindings = lib.mkIf cfg.hyprlandBinding [
      {
        _args = [
          (lib.generators.mkLuaInline ''mod .. " + ALT + RETURN"'')
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[omanix-term --cwd="$(omanix-cmd-terminal-cwd)" -- bash -c 'tmux attach || tmux new -s Work']])'')
          { description = "Tmux"; }
        ];
      }
    ];
  };
}
