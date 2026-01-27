{ config, pkgs, inputs, lib, ... }:
{
  # 1. Fix Bootloader Assertion
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  
  # 2. Fix Filesystem Assertion (Dummy)
  fileSystems."/" = { device = "/dev/dummy"; fsType = "ext4"; };

  # 3. Fix XDG Portal Assertion
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Home Manager setup
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.dev = { pkgs, ... }: {
      home.username = "dev";
      home.homeDirectory = lib.mkForce "/home/dev";
      home.stateVersion = "24.11";
      omarchy.theme = "tokyo-night"; 
    };
  };

  users.users.dev = {
    isNormalUser = true;
    home = "/home/dev";
    uid = 1000;
    group = "users";
  };

  system.stateVersion = "24.11";
}
