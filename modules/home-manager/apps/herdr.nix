{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.herdr;
in
{
  options.omanix.apps.herdr = {
    enable = lib.mkEnableOption "herdr agent multiplexer with AI dev layouts";

    aiCommand = lib.mkOption {
      type = lib.types.str;
      default = "claude";
      description = "AI CLI command used in the ih layout alias (e.g. claude, opencode)";
    };

    hyprlandBinding = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add Super+Ctrl+Return (launch herdr) and Super+Ctrl+K (keybindings) bindings";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.herdr ];

    # Mirrors the Omanix tmux config in apps/tmux.nix.
    # tmux session -> herdr workspace, tmux window -> herdr tab, tmux pane -> herdr pane.
    xdg.configFile."herdr/config.toml".text = ''
      [theme]
      # tmux ran on the terminal's own palette (bg=default, fg=default, ANSI blue accents)
      name = "terminal"

      [theme.custom]
      # The active tab is drawn as panel_bg text on an accent background, so panel_bg
      # has to be dark for it to read - same colors as status-left's "#[fg=black,bg=blue]"
      panel_bg = "black"

      [terminal]
      # Matches -c "#{pane_current_path}" on every split, window, and session
      new_cwd = "follow"

      [keys]
      prefix = "ctrl+space"

      # Config and help
      reload_config = "prefix+q"
      help = "prefix+?"
      detach = "prefix+d"

      # Copy mode
      copy_mode = "prefix+["

      # Panes
      split_horizontal = ["prefix+h", "alt+enter"]
      split_vertical = ["prefix+v", "alt+shift+enter"]
      close_pane = ["prefix+x", "alt+esc"]
      zoom = "prefix+z"
      last_pane = "prefix+;"

      focus_pane_left = "ctrl+alt+left"
      focus_pane_down = "ctrl+alt+down"
      focus_pane_up = "ctrl+alt+up"
      focus_pane_right = "ctrl+alt+right"

      resize_mode = ["prefix+ctrl+left", "prefix+ctrl+down", "prefix+ctrl+up", "prefix+ctrl+right"]

      # Like resize-pane on C-M-S-arrows
      resize_pane_left = "ctrl+alt+shift+left"
      resize_pane_down = "ctrl+alt+shift+down"
      resize_pane_up = "ctrl+alt+shift+up"
      resize_pane_right = "ctrl+alt+shift+right"

      # No tmux equivalent; herdr's default prefix+shift+p is taken by previous session
      rename_pane = "prefix+shift+o"

      # Windows -> tabs
      new_tab = "prefix+c"
      rename_tab = "prefix+r"
      close_tab = "prefix+k"
      switch_tab = ["prefix+1..9", "alt+1..9"]
      previous_tab = ["prefix+p", "alt+left"]
      next_tab = ["prefix+n", "alt+right"]

      # Like swap-window -t -1/+1 on M-S-Left/Right
      move_tab_previous = "alt+shift+left"
      move_tab_next = "alt+shift+right"

      # Sessions -> workspaces
      new_workspace = "prefix+shift+c"
      rename_workspace = "prefix+shift+r"
      close_workspace = "prefix+shift+k"
      previous_workspace = ["prefix+shift+p", "alt+up"]
      next_workspace = ["prefix+shift+n", "alt+down"]

      [ui]
      accent = "blue"

      # tmux drew single-line dividers between adjacent panes and no outer frame
      pane_gaps = false
      pane_outer_borders = false

      # tmux had no scrollbar column beside its panes
      pane_scrollbars = false

      # kill-window and kill-session never asked
      confirm_close = false

      # automatic-rename gave windows a name without prompting
      prompt_new_tab_name = false

      # set -g mouse on
      mouse_capture = true

      # status-right had the zoom flag followed by #h
      tab_bar_right = [{ type = "zoom" }, { type = "hostname" }]

      # set -g set-titles on / set -g set-titles-string '#h:#W', where tmux's #W was
      # the basename of the pane cwd. This is what Hyprland shows in the group bar,
      # and it resolves on the server so remote sessions name the remote host.
      window_title = "{hostname}: {workspace}"
    '';

    programs.zsh = {
      shellAliases = {
        h = "herdr";
        ih = "hdl ${cfg.aiCommand}";
      };

      initContent = lib.mkAfter ''
        # Echo a split ratio as a float
        # Usage: _herdr_ratio <numerator> <denominator>
        _herdr_ratio() {
          awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a / b }'
        }

        # Split a herdr pane and echo the id of the new pane
        # Usage: _herdr_split <pane_id> <right|down> <ratio> <cwd>
        _herdr_split() {
          herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus |
            jq -r '.result.pane.pane_id'
        }

        # Create a Herdr Dev Layout with editor, ai, and terminal
        # Usage: hdl <c|cx|codex|other_ai> [<second_ai>]
        hdl() {
          [[ -z $1 ]] && { echo "Usage: hdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
          [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdl."; return 1; }

          local current_dir="''${PWD}"
          local editor_pane ai_pane ai2_pane
          local ai="$1"
          local ai2="''${2:-}"

          # Use HERDR_PANE_ID for the pane we're running in (stable even if focus moves)
          editor_pane="$HERDR_PANE_ID"

          # Name the current tab after the base directory name
          herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

          # Split tab vertically - top 85%, bottom 15%
          _herdr_split "$editor_pane" down 0.85 "$current_dir" >/dev/null

          # Split editor pane horizontally - AI on right 30%
          ai_pane=$(_herdr_split "$editor_pane" right 0.7 "$current_dir")

          # If second AI provided, split the AI pane vertically
          if [[ -n $ai2 ]]; then
            ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$current_dir")
            herdr pane run "$ai2_pane" "$ai2" >/dev/null
          fi

          # Run ai in the right pane
          herdr pane run "$ai_pane" "$ai" >/dev/null

          # Run the editor in the left pane
          herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
        }

        # Create a Herdr Dev Square layout with editor, diff watch, terminal, and opencode
        # Usage: hds
        # hunk (diff --watch) and opencode are optional; those panes error gracefully if absent.
        hds() {
          [[ -n $1 ]] && { echo "Usage: hds"; return 1; }
          [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hds."; return 1; }

          local current_dir="''${PWD}"
          local editor_pane diff_pane terminal_pane opencode_pane

          editor_pane="$HERDR_PANE_ID"

          herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

          terminal_pane=$(_herdr_split "$editor_pane" down 0.5 "$current_dir")
          diff_pane=$(_herdr_split "$editor_pane" right 0.5 "$current_dir")
          opencode_pane=$(_herdr_split "$terminal_pane" right 0.5 "$current_dir")

          herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
          herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null
          herdr pane run "$opencode_pane" "opencode" >/dev/null
        }

        # Create multiple hdl tabs with one per subdirectory in the current directory
        # Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]
        hdlm() {
          [[ -z $1 ]] && { echo "Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
          [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdlm."; return 1; }

          local ai="$1"
          local ai2="''${2:-}"
          local base_dir="$PWD"
          local first=true
          local hdl_command

          # Rename the workspace to the current directory name
          herdr workspace rename "$HERDR_WORKSPACE_ID" "$(basename "$base_dir")" >/dev/null

          for dir in "$base_dir"/*/; do
            [[ -d $dir ]] || continue
            local dirpath="''${dir%/}"

            hdl_command=$(printf 'hdl %q' "$ai")
            [[ -n $ai2 ]] && hdl_command=$(printf '%s %q' "$hdl_command" "$ai2")

            if $first; then
              # Reuse the current tab for the first project
              hdl_command=$(printf 'cd %q && %s' "$dirpath" "$hdl_command")
              herdr pane run "$HERDR_PANE_ID" "$hdl_command" >/dev/null
              first=false
            else
              local pane_id
              pane_id=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$dirpath" --no-focus |
                jq -r '.result.root_pane.pane_id')
              herdr pane run "$pane_id" "$hdl_command" >/dev/null
            fi
          done
        }

        # Create a multi-pane swarm layout with the same command started in each pane (great for AI)
        # Usage: hsl <pane_count> <command>
        hsl() {
          [[ -z $1 || -z $2 ]] && { echo "Usage: hsl <pane_count> <command>"; return 1; }
          [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hsl."; return 1; }

          local count="$1"
          local cmd="$2"
          local current_dir="''${PWD}"
          local -a columns panes

          herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

          # Tile into a grid: ceil(sqrt(count)) columns, rows spread across them
          local cols=1
          while (( cols * cols < count )); do ((cols++)); done

          # Even columns come from splitting the rightmost one off at 1/(n-k+1) each time,
          # which keeps the array in left-to-right order
          columns=("$HERDR_PANE_ID")
          local k
          for (( k = 1; k < cols; k++ )); do
            columns+=("$(_herdr_split "''${columns[-1]}" right "$(_herdr_ratio 1 $((cols - k + 1)))" "$current_dir")")
          done

          # Split each column into its share of rows, again evenly and top-to-bottom.
          # zsh arrays are 1-indexed, so columns run 1..cols.
          local col index rows j last
          for (( index = 1; index <= cols; index++ )); do
            col="''${columns[index]}"
            rows=$(( count / cols ))
            (( index <= count % cols )) && (( rows++ ))
            panes+=("$col")
            last="$col"
            for (( j = 1; j < rows; j++ )); do
              last=$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows - j + 1)))" "$current_dir")
              panes+=("$last")
            done
          done

          local pane
          for pane in "''${panes[@]}"; do
            herdr pane run "$pane" "$cmd" >/dev/null
          done
        }
      '';
    };

    omanix.hyprland.extraBindings = lib.mkIf cfg.hyprlandBinding [
      {
        _args = [
          (lib.generators.mkLuaInline ''mod .. " + CTRL + RETURN"'')
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[omanix-term --cwd="$(omanix-cmd-terminal-cwd)" -- herdr]])'')
          { description = "Herdr"; }
        ];
      }
      {
        _args = [
          (lib.generators.mkLuaInline ''mod .. " + CTRL + K"'')
          (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[omanix-menu-herdr-keybindings]])'')
          { description = "Herdr keybindings"; }
        ];
      }
    ];
  };
}
