# Getting Started

## Add Omanix to Your Flake

The example below tracks `main`. To pin a release instead, use one of:

```nix
omanix.url = "github:T00fy/omanix/v2.1.1";                     # exact tag
omanix.url = "https://flakehub.com/f/T00fy/omanix/2.*";         # latest 2.x
```

Releases follow semver: a major bump means some `omanix.*` options changed and
your config may need updating — check the
[changelog](https://github.com/T00fy/omanix/blob/main/CHANGELOG.md) first.

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omanix = {
      url = "github:T00fy/omanix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, omanix, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix

        # System-level module
        omanix.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.yourname = {
              imports = [ omanix.homeManagerModules.default ];
              home.stateVersion = "24.11";

              omanix = {
                user = {
                  name = "Your Name";
                  email = "you@example.com";
                };
              };
            };
          };
        }
      ];
    };
  };
}
```

## Enable the System Module

In your NixOS configuration (or inline in the flake):

```nix
omanix = {
  enable = true;
  theme = "tokyo-night";
  wallpaperIndex = 0;
};
```

## Rebuild

```bash
sudo nixos-rebuild switch --flake .
```

Once built there's a convenience alias provided: `rebuild`
