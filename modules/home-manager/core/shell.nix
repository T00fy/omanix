{ pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''
        # Only End key accepts full suggestion
        ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line)
        bindkey '^[[F' end-of-line

        # Right arrow just moves cursor (forward-char is not in accept list)
        bindkey '^[[C' forward-char

        bindkey '^R' fzf-history-widget

      '';
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "fzf"
          "sudo"
          "docker"
          "kubectl"
          "history"
          "dirhistory"
          "extract"
          "z"
          "colored-man-pages"
          "command-not-found"
          "copypath"
          "copyfile"
        ];
        theme = "";
      };

      history = {
        size = 10000;
        save = 10000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = true;
      };

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        ls = "eza -lh --group-directories-first --icons=auto";
        lt = "eza --tree --level=2 --long --icons --git";
        ll = "eza -l --icons=auto";
        la = "eza -la --icons=auto";
        pbcopy = "wl-copy";
        pbpaste = "wl-paste";
        cat = "bat -pp";

        rebuild = "sudo nixos-rebuild switch --flake .";
        nix-clean = "sudo nix-collect-garbage -d";
        nix-search = "nix search nixpkgs";
      };

      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        TERMINAL = "ghostty";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 200;
        format = "[$directory$git_branch$git_status]($style)$character";
        character = {
          success_symbol = "[❯](bold cyan)";
          error_symbol = "[✗](bold cyan)";
        };
        directory = {
          truncation_length = 2;
          truncation_symbol = "…/";
          style = "bold cyan";
        };
        git_branch = {
          format = "[$branch]($style) ";
          style = "italic cyan";
        };
      };
    };
  };

  home.sessionVariables = {
    XDG_TERMINAL_EXEC_FALLBACK = "com.mitchellh.ghostty.desktop";
  };
  home.packages = with pkgs; [
    eza
    ripgrep
    fd
    fzf
    zsh-completions
    xdg-terminal-exec
  ];

}
