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
        ttfx = final.callPackage ./pkgs/ttfx { };
        omanix-scripts = final.callPackage ./pkgs/omanix-scripts { };
        omanix-shell = final.callPackage ./pkgs/omanix-shell { };
        omanix-agent-usage = final.callPackage ./pkgs/omanix-agent-usage { };
        omanix-audio-tunings = final.callPackage ./pkgs/omanix-audio-tunings { };
        wlctl = inputs.wlctl.packages.${prev.stdenv.hostPlatform.system}.default;

        # Give Quickshell's Qt the webp (+ heif/avif/…) image plugin so QML
        # `Image` can decode webp — theme wallpapers and user-picked backgrounds
        # render natively instead of black. Mirrors omarchy, which ships
        # qt6-imageformats alongside quickshell (install/omarchy-base.packages);
        # omarchy draws its wallpaper through the same Quickshell path, not swww.
        #
        # Wrap the cached binary rather than overrideAttrs (buildInputs) so the
        # upstream quickshell is still substituted from the binary cache instead
        # of recompiled: QT_PLUGIN_PATH is read at runtime and merges with the
        # inner Qt wrapper's paths, so prefixing qtimageformats' plugin dir is
        # enough to make libqwebp discoverable.
        quickshell = prev.symlinkJoin {
          name = "quickshell-webp";
          paths = [ prev.quickshell ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            for b in qs quickshell; do
              wrapProgram "$out/bin/$b" \
                --prefix QT_PLUGIN_PATH : "${prev.qt6.qtimageformats}/lib/qt-6/plugins"
            done
          '';
          inherit (prev.quickshell) meta;
        };

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

      packages.x86_64-linux.omanix-shell =
        (import nixpkgs {
          system = "x86_64-linux";
          overlays = [ self.overlays.default ];
        }).omanix-shell;

      packages.x86_64-linux.omanix-agent-usage =
        (import nixpkgs {
          system = "x86_64-linux";
          overlays = [ self.overlays.default ];
        }).omanix-agent-usage;

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
          ];

          _module.args.omanixLib = omanixLib;
          _module.args.inputs = inputs;
        };
    };
}
