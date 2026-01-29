{ config, pkgs, lib, ... }:
let
  cfg = config.omarchy.neovim;
  lang = config.omarchy.languages;
in
{
  options.omarchy.neovim = {
    enable = lib.mkEnableOption "Neovim with LazyVim" // { default = true; };

    extraTreesitterParsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional treesitter parsers to install";
      example = [ "mermaid" "hcl" ];
    };
  };

  config = lib.mkIf cfg.enable {
    programs.lazyvim = {
      enable = true;

      # Wire up LazyVim extras based on enabled languages
      extras = {
        lang.nix.enable = lang.nix.enable;
        lang.markdown.enable = lang.markdown.enable;
        lang.json.enable = lang.json.enable;
        lang.docker.enable = lang.docker.enable;

        lang.rust = lib.mkIf lang.rust.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
        lang.go = lib.mkIf lang.go.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
        lang.java = lib.mkIf lang.java.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
        lang.terraform = lib.mkIf lang.terraform.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
        lang.typescript = lib.mkIf lang.typescript.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
        lang.tailwind = lib.mkIf lang.tailwind.enable {
          enable = true;
          installDependencies = false;
          installRuntimeDependencies = false;
        };
      };

      extraPackages = with pkgs; [
        # Always needed for treesitter compilation
        gcc
        tree-sitter
      ];

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

        autocmds = lib.concatStringsSep "\n" (lib.flatten [
          # Dart LSP setup
          (lib.optional lang.dart.enable ''
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "dart" },
              callback = function()
                vim.lsp.start({
                  name = "dartls",
                  cmd = { "dart", "language-server", "--protocol=lsp" },
                  root_dir = vim.fs.dirname(
                    vim.fs.find({ "pubspec.yaml", ".git" }, { upward = true })[1]
                  ),
                  settings = {
                    dart = {
                      completeFunctionCalls = true,
                      showTodos = true,
                    },
                  },
                })
              end,
            })
          '')

          # Extra treesitter parsers
          (lib.optional (cfg.extraTreesitterParsers != [ ]) ''
            vim.api.nvim_create_autocmd("User", {
              pattern = "LazyVimStarted",
              callback = function()
                local ts_configs = require("nvim-treesitter.configs")
                local parsers = ${builtins.toJSON cfg.extraTreesitterParsers}
                for _, parser in ipairs(parsers) do
                  vim.cmd("TSInstall " .. parser)
                end
              end,
              once = true,
            })
          '')
        ]);
      };
    };
  };
}
