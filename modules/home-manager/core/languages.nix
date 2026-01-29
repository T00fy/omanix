{ config, pkgs, lib, ... }:
let
  cfg = config.omarchy.languages;
in
{
  options.omarchy.languages = {
    nix.enable = lib.mkEnableOption "Nix development tools" // { default = true; };
    markdown.enable = lib.mkEnableOption "Markdown tools" // { default = true; };
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
    home.packages = with pkgs; lib.flatten [
      # Nix
      (lib.optionals cfg.nix.enable [
        nixd
        nixfmt  # was nixfmt-rfc-style, now just nixfmt
      ])

      # Markdown
      (lib.optionals cfg.markdown.enable [
        marksman
        markdownlint-cli
      ])

      # Rust
      (lib.optionals cfg.rust.enable [
        rustc
        cargo
        rust-analyzer
        rustfmt
        clippy
      ])

      # Go
      (lib.optionals cfg.go.enable [
        go
        gopls
        gotools
        golangci-lint
        delve
      ])

      # Java
      (lib.optionals cfg.java.enable [
        jdk
        jdt-language-server
        maven
        gradle
      ])

      # Docker
      (lib.optionals cfg.docker.enable [
        dockerfile-language-server  # was dockerfile-language-server-nodejs
        docker-compose-language-service
        hadolint
      ])

      # Terraform
      (lib.optionals cfg.terraform.enable [
        terraform
        terraform-ls
        tflint
      ])

      # TypeScript/JavaScript
      (lib.optionals cfg.typescript.enable [
        nodejs
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.prettier
        nodePackages.eslint
        vscode-langservers-extracted
        emmet-language-server
      ])

      # Tailwind
      (lib.optionals cfg.tailwind.enable [
        tailwindcss-language-server
      ])

      # JSON (if not already from typescript)
      (lib.optionals (cfg.json.enable && !cfg.typescript.enable) [
        vscode-langservers-extracted
      ])

      # Dart/Flutter - flutter includes dart, so only install flutter
      (lib.optionals cfg.dart.enable [
        flutter  # includes dart SDK
      ])
    ];
  };
}
