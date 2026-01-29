{ config, pkgs, ... }:
{
  programs.lazyvim = {
    enable = true;

    # Start minimal - only nix for now
    extras = {
      lang.nix.enable = true;
      lang.markdown.enable = true;
      
      # These seem to pull in yaml treesitter which has hash issues
      # lang.json.enable = true;
      # lang.typescript = {
      #   enable = true;
      #   installDependencies = true;
      #   installRuntimeDependencies = true;
      # };
      # lang.toml.enable = true;
    };

    # Additional packages for LSP/tooling
    extraPackages = with pkgs; [
      nixd        # Nix LSP (better than nil)
      nixfmt      # Nix formatter (nixfmt-rfc-style is now just nixfmt)
      
      # For treesitter (silences health check warnings)
      gcc
      tree-sitter
    ];

    # Custom options
    config = {
      options = ''
        vim.opt.relativenumber = true
        vim.opt.scrolloff = 8
        vim.opt.wrap = false
        
        -- Suppress helptags errors on NixOS (nix store is read-only)
        vim.g.lazy_did_setup = true
      '';

      keymaps = ''
        vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
      '';
    };
  };
}
