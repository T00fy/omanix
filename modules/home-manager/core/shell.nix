{ config, pkgs, ... }:
{
  # Keep Starship (Omarchy requirement)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # ... keep settings from previous step ...
  };

  # Configure Zsh with Oh My Zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Enable Oh My Zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "fzf" ];
      # We don't set a theme because Starship overrides it
    };

    # Omarchy-specific Aliases (Keep these to match upstream behavior)
    shellAliases = {
      ".." = "cd ..";
      ls = "${pkgs.eza}/bin/eza -lh --group-directories-first --icons=auto";
      # ... add the rest of the Omarchy aliases here ...
    };
    
    # Environment
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "ghostty";
    };
  };
  
  # Packages
  home.packages = with pkgs; [ eza fzf bat zoxide ];
}
