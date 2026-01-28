{ config, pkgs, ... }:
{
  # Enable Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
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
      # We use Starship for the prompt, so no theme needed
      theme = "";
    };

    # History settings
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Omarchy-like Aliases
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      ls = "eza -lh --group-directories-first --icons=auto";
      lt = "eza --tree --level=2 --long --icons --git";
      ll = "eza -l --icons=auto";
      la = "eza -la --icons=auto";
      
      # Nix specific shortcuts
      rebuild = "sudo nixos-rebuild switch --flake .";
      nix-clean = "sudo nix-collect-garbage -d";
      nix-search = "nix search nixpkgs";
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "ghostty";
    };
  };

  # Starship prompt (works great with Zsh)
  programs.starship = {
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

  # Ensure these tools are present for the aliases
  home.packages = with pkgs; [ 
    eza 
    ripgrep 
    fd 
    fzf 
    bat
    zsh-completions
  ];
}
