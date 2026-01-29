{ config, pkgs, inputs, lib, ... }:
{
  boot.loader.systemd-boot.enable = true;
  fileSystems."/" = { device = "/dev/dummy"; fsType = "ext4"; };
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # Enable the system-level Hyprland stub (required for many Wayland tools)
  programs.hyprland.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.dev = { pkgs, ... }: {
      home.username = "dev";
      home.homeDirectory = lib.mkForce "/home/dev";
      home.stateVersion = "24.11";
      
      # This triggers Phase 1 logic
      omanix.theme = "tokyo-night"; 
      
      # This triggers Phase 2 & 3 logic via the default imports
      # (Ensure your modules/home-manager/default.nix is updated with all imports)
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
