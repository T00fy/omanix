{ config, pkgs, ... }:
{
  # 1. Enable Starship (The prompt)
  programs.starship = {
    enable = true;
    # Copy Omarchy's config structure
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

  # 2. Configure Bash (Aliases & Env)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Enable Oh My Zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "fzf" ];
    };
     
    # Omarchy-like Aliases
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      ls = "${pkgs.eza}/bin/eza -lh --group-directories-first --icons=auto";
      lsa = "${pkgs.eza}/bin/eza -lh --group-directories-first --icons=auto -a";
      lt = "${pkgs.eza}/bin/eza --tree --level=2 --long --icons --git";
      
      # Nix specific shortcuts
      rebuild = "sudo nixos-rebuild switch --flake .";
    };

    # Environment variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "ghostty";
    };
  };
  
  # Ensure these tools are present for the aliases
  home.packages = with pkgs; [ eza ripgrep fd fzf bat ];
}
