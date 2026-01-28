{ config, lib, pkgs, ... }:
{
  # Existing font config...
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      autohint = false;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  
  # Enable the Bluetooth service
  services.blueman.enable = true;
  programs.zsh.enable = true;

  # 2. Set as default shell for users
  users.defaultUserShell = pkgs.zsh;
}
