{ config, pkgs, lib, ... }:
let
  cfg = config.omanix.languages;
  
  # Wrapper that provides 'terraform' command pointing to opentofu
  terraformAlias = pkgs.writeShellScriptBin "terraform" ''
    exec ${pkgs.opentofu}/bin/tofu "$@"
  '';
in
{
  options.omanix.languages = {
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
      # Nix - LSP, formatter, linter
      (lib.optionals cfg.nix.enable [
        nixd              # LSP
        nixfmt            # formatter
        statix            # linter (required by LazyVim lang.nix)
        deadnix           # dead code finder
      ])

      # Markdown - LSP, linter
      (lib.optionals cfg.markdown.enable [
        marksman          # LSP
        markdownlint-cli2 # linter (required by LazyVim lang.markdown)
      ])

      # Rust - toolchain, LSP, tools
      (lib.optionals cfg.rust.enable [
        rustc
        cargo
        rust-analyzer     # LSP
        rustfmt           # formatter
        clippy            # linter
      ])

      # Go - toolchain, LSP, tools
      (lib.optionals cfg.go.enable [
        go
        gopls             # LSP
        gotools           # goimports, etc
        golangci-lint     # linter
        delve             # debugger
        gomodifytags      # struct tag tool
        impl              # interface stub generator
        gotests           # test generator
      ])

      # Java - JDK, LSP, build tools
      (lib.optionals cfg.java.enable [
        jdk
        jdt-language-server
        maven
        gradle
      ])

      # Docker - LSPs, linter
      (lib.optionals cfg.docker.enable [
        dockerfile-language-server
        docker-compose-language-service
        hadolint          # Dockerfile linter
      ])

      # OpenTofu (Terraform-compatible) - CLI, LSP, linter
      (lib.optionals cfg.terraform.enable [
        opentofu
        terraformAlias    # provides 'terraform' command
        terraform-ls      # LSP
        tflint            # linter
      ])

      # TypeScript/JavaScript - runtime, LSPs, tools
      (lib.optionals cfg.typescript.enable [
        nodejs
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.prettier
        vscode-langservers-extracted  # html, css, json, eslint LSPs
        emmet-language-server
      ])

      # Tailwind - LSP
      (lib.optionals cfg.tailwind.enable [
        tailwindcss-language-server
      ])

      # JSON - LSP (if not already from typescript)
      (lib.optionals (cfg.json.enable && !cfg.typescript.enable) [
        vscode-langservers-extracted
      ])

      # Dart/Flutter - SDK (includes dart language-server)
      (lib.optionals cfg.dart.enable [
        flutter
      ])
    ];
  };
}
