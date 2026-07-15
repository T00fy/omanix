{
  description = "Omanix - Omarchy for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland/v0.55.2";

    nix-colors.url = "github:misterio77/nix-colors";

    lazyvim = {
      url = "github:pfassina/lazyvim-nix/v15.14.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wlctl = {
      url = "github:aashish-thapa/wlctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yt-dlp-src = {
      url = "github:yt-dlp/yt-dlp";
      flake = false;
    };

    # Up-to-date AI agent CLIs (Claude Code, OpenCode, ...). Deliberately does
    # NOT follow our nixpkgs: the `default` overlay builds against the flake's
    # own pinned nixpkgs so the Numtide binary cache hits instead of rebuilding.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      lazyvim,
      walker,
      elephant,
      silentSDDM,
      wlctl,
      ...
    }@inputs:
    let
      omanixLib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      lib = omanixLib;

      # ═══════════════════════════════════════════════════════════════════
      # NixOS Module (system-level configuration)
      # ═══════════════════════════════════════════════════════════════════

      overlays.default = final: prev: {
        spotatui = prev.callPackage inputs.spotatui { };
        omanix-screensaver = final.callPackage ./pkgs/omanix-screensaver { };
        omanix-scripts = final.callPackage ./pkgs/omanix-scripts { };
        wlctl = inputs.wlctl.packages.${prev.stdenv.hostPlatform.system}.default;

        yt-dlp = prev.yt-dlp.overrideAttrs (oldAttrs: {
          src = inputs.yt-dlp-src;
          version = "master";
          doCheck = false;
        });
      };

      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          imports = [
            ./modules/nixos
            silentSDDM.nixosModules.default
          ];

          nixpkgs.overlays = [
            self.overlays.default
            inputs.llm-agents.overlays.shared-nixpkgs
          ];
        };

      # ═══════════════════════════════════════════════════════════════════
      # Packages (documentation, etc.)
      # ═══════════════════════════════════════════════════════════════════
      packages.x86_64-linux.docs = import ./docs/generate-options.nix {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        inherit (nixpkgs) lib;
        inherit self inputs home-manager;
        inherit omanixLib;
      };

      # ═══════════════════════════════════════════════════════════════════
      # Home Manager Module (user-level configuration)
      # ═══════════════════════════════════════════════════════════════════
      homeManagerModules.default =
        {
          config,
          pkgs,
          lib,
          osConfig ? null,
          ...
        }:
        {
          imports = [
            ./modules/home-manager
            lazyvim.homeManagerModules.default
            walker.homeManagerModules.default
          ];

          _module.args.omanixLib = omanixLib;
          _module.args.inputs = inputs;
        };
    };
}
