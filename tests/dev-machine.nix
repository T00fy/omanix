{ config, pkgs, ... }:
{
  # Minimal dummy config for testing module evaluation
  boot.loader.systemd-boot.enable = true;
  fileSystems."/" = { device = "/dev/dummy"; fsType = "ext4"; };
  
  # Enable Home Manager so we can test your module
  home-manager.users.dev = { pkgs, ... }: {
    home.stateVersion = "24.11";
    # We don't need to import the module here explicitly because 
    # flake.nix injects it into this configuration
    omarchy.theme = "tokyo-night"; 
  };

  system.stateVersion = "24.11";
}
