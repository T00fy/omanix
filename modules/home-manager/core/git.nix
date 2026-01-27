{ config, lib, ... }:
let
  cfg = config.omarchy;
in
{
  # Define options to accept user info
  options.omarchy.user = {
    name = lib.mkOption { type = lib.types.str; };
    email = lib.mkOption { type = lib.types.str; };
  };

  config = {
    programs.git = {
      enable = true;
      userName = cfg.user.name;
      userEmail = cfg.user.email;
      
      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
      };
    };
  };
}
