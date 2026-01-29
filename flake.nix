{
  description = "Omanix - Omarchy for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland/v0.53.3";

    # We keep this for future access to base16 schemes, but we won't use it for math.
    nix-colors.url = "github:misterio77/nix-colors";

    # LazyVim for NixOS
    lazyvim.url = "github:pfassina/lazyvim-nix/v15.13.0";
    walker.url = "github:abenz1267/walker";
    elephant.url = "github:abenz1267/elephant";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      lazyvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      # We instantiate our custom lib here using nixpkgs lib
      omarchyLib = import ./lib {
        inherit (nixpkgs) lib;
      };
    in
    {
      # Export the library for external use
      lib = omarchyLib;
      nixosModules.default = import ./modules/nixos;

      # Home Manager module (user-level)
      homeManagerModules.default =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        {
          imports = [
            ./modules/home-manager
            lazyvim.homeManagerModules.default
          ];
          # Pass our custom lib down to modules so we can access themes/utils
          _module.args.omarchyLib = omarchyLib;
        };

      # Development/testing configuration
      nixosConfigurations.omanix-dev = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./tests/dev-machine.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.users.dev = {
              imports = [ self.homeManagerModules.default ];
            };
          }
        ];
      };
    };
}
