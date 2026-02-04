{ config, lib, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.user = {
    name = lib.mkOption { type = lib.types.str; };
    email = lib.mkOption { type = lib.types.str; };
  };

  config = {
    programs.git = {
      enable = true;

      settings = {
        user = {
          inherit (cfg.user) name;
          inherit (cfg.user) email;
        };
        init.defaultBranch = "main";
        core.editor = "nvim";
      };
    };
  };
}
