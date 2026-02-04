{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.languages;

  terraformAlias = pkgs.writeShellScriptBin "terraform" ''
    exec ${pkgs.opentofu}/bin/tofu "$@"
  '';
in
{
  options.omanix.languages = {
    nix.enable = lib.mkEnableOption "Nix development tools" // {
      default = true;
    };
    markdown.enable = lib.mkEnableOption "Markdown tools" // {
      default = true;
    };
    rust.enable = lib.mkEnableOption "Rust toolchain";
    go.enable = lib.mkEnableOption "Go toolchain";
    java.enable = lib.mkEnableOption "Java toolchain";
    docker.enable = lib.mkEnableOption "Docker tools";
    terraform.enable = lib.mkEnableOption "Terraform toolchain";
    typescript.enable = lib.mkEnableOption "TypeScript/JavaScript toolchain";
    tailwind.enable = lib.mkEnableOption "Tailwind CSS tools";
    json.enable = lib.mkEnableOption "JSON tools";
    dart.enable = lib.mkEnableOption "Dart/Flutter toolchain";
  };

  config = {
    home.packages =
      with pkgs;
      lib.flatten [
        (lib.optionals cfg.nix.enable [
          nixd
          nixfmt
          statix
          deadnix
        ])

        (lib.optionals cfg.markdown.enable [
          marksman
          markdownlint-cli2
        ])

        (lib.optionals cfg.rust.enable [
          rustc
          cargo
          rust-analyzer
          rustfmt
          clippy
        ])

        (lib.optionals cfg.go.enable [
          go
          gopls
          gotools
          golangci-lint
          delve
          gomodifytags
          impl
          gotests
        ])

        (lib.optionals cfg.java.enable [
          jdk
          jdt-language-server
          maven
          gradle
        ])

        (lib.optionals cfg.docker.enable [
          dockerfile-language-server
          docker-compose-language-service
          hadolint
        ])

        (lib.optionals cfg.terraform.enable [
          opentofu
          terraformAlias
          terraform-ls
          tflint
        ])

        (lib.optionals cfg.typescript.enable [
          nodejs
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodePackages.prettier
          vscode-langservers-extracted
          emmet-language-server
        ])

        (lib.optionals cfg.tailwind.enable [
          tailwindcss-language-server
        ])

        (lib.optionals (cfg.json.enable && !cfg.typescript.enable) [
          vscode-langservers-extracted
        ])

        (lib.optionals cfg.dart.enable [
          flutter
        ])
      ];
  };
}
