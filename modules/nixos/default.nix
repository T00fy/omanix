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
}
