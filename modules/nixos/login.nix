{ config, lib, pkgs, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.login = {
    enable = lib.mkEnableOption "Omanix login screen (SDDM)" // { default = true; };
  };

  config = lib.mkIf (cfg.enable && cfg.login.enable) {
    programs.silentSDDM = {
      enable = true;
      theme = "catppuccin-mocha";
    };
  };
}
