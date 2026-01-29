{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  # Define options to accept user info
  options.omanix.user = {
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
