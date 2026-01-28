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
      
      settings = {
        user = {
          name = cfg.user.name;
          email = cfg.user.email;
        };
        init.defaultBranch = "main";
        core.editor = "nvim";
      };
    };
  };
}
