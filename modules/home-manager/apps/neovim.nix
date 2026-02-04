{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.neovim;
  lang = config.omanix.languages;
in
{
  options.omanix.neovim = {
    enable = lib.mkEnableOption "Neovim with LazyVim" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.lazyvim = {
      enable = true;

      installCoreDependencies = true;
      extras = {
        lang = {
          nix = lib.mkIf lang.nix.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          markdown = lib.mkIf lang.markdown.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          json = lib.mkIf lang.json.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          docker = lib.mkIf lang.docker.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          rust = lib.mkIf lang.rust.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          go = lib.mkIf lang.go.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          java = lib.mkIf lang.java.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          terraform = lib.mkIf lang.terraform.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          typescript = lib.mkIf lang.typescript.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
          tailwind = lib.mkIf lang.tailwind.enable {
            enable = true;
            installDependencies = false;
            installRuntimeDependencies = false;
          };
        };
      };

      extraPackages = with pkgs; [
        gcc
        tree-sitter
      ];

      config = {
        options = ''
          vim.opt.relativenumber = true
          vim.opt.scrolloff = 8
          vim.opt.wrap = false
        '';

        keymaps = ''
          vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
        '';

        autocmds = lib.optionalString lang.dart.enable ''
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
        '';
      };
    };

    xdg.configFile."nvim/lua/plugins/init.lua".text = ''
      return {}
    '';
  };
}
