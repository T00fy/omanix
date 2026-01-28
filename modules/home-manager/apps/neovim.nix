{ config, pkgs, ... }:
{
  programs.lazyvim = {
    enable = true;

    # Language support - enable what you need
    extras = {
      lang.nix.enable = true;
      lang.typescript = {
        enable = true;
        installDependencies = true;
        installRuntimeDependencies = true;
      };
      lang.json.enable = true;
      lang.markdown.enable = true;
      lang.yaml.enable = true;
      lang.toml.enable = true;
      
      # Uncomment languages you want:
      # lang.python = {
      #   enable = true;
      #   installDependencies = true;
      #   installRuntimeDependencies = true;
      # };
      # lang.rust = {
      #   enable = true;
      #   installDependencies = true;
      # };
      # lang.go = {
      #   enable = true;
      #   installDependencies = true;
      #   installRuntimeDependencies = true;
      # };
    };

    # Additional packages for LSP/tooling
    extraPackages = with pkgs; [
      nixd        # Nix LSP (better than nil)
      nixfmt-rfc-style  # Nix formatter
    ];

    # Custom keymaps
    config = {
      options = ''
        -- Custom options
        vim.opt.relativenumber = true
        vim.opt.scrolloff = 8
        vim.opt.wrap = false
      '';

      keymaps = ''
        -- Custom keymaps
        vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
      '';
    };

    # Custom plugins (optional)
    # plugins = {
    #   colorscheme = ''
    #     return {
    #       "catppuccin/nvim",
    #       opts = { flavour = "mocha" },
    #     }
    #   '';
    # };
  };
}
