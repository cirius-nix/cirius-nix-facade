{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [
        namespace
        "editor"
        "nvim"
        "settings"
        "lsp"
        "servers"
      ]
      [
        "programs"
        "nixvim"
        "lsp"
        "servers"
      ]
    )
  ];
  options.${namespace}.editor.nvim = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Neovim editor.";
    };
    settings = {
      # leader key
      leaderKey = lib.mkOption {
        type = lib.types.str;
        default = " ";
        description = "Leader key for Neovim.";
      };

      options = {
        useRecommendation = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use recommended Neovim settings.";
        };
        extends = lib.mkOption {
          type = with lib.types; attrsOf anything;
          default = { };
          description = "Extend Neovim settings with additional options.";
        };
      };

    };
  };

  config =
    let
      inherit (lib.${namespace}.nvim) mkKeymap;
      inherit (config.${namespace}.editor.nvim) enable settings;

      recommendedOptions = {
        clipboard = "unnamedplus";
        timeout = true;
        autowrite = true;
        conceallevel = 3;
        confirm = true;
        cursorline = true;
        expandtab = true;
        formatoptions = "jcroqlnt";
        grepformat = "%f:%l:%c:%m";
        grepprg = "rg --vimgrep";
        ignorecase = true;
        inccommand = "nosplit";
        laststatus = 3;
        list = true;
        mouse = "a";
        number = true;
        pumblend = 10;
        pumheight = 10;
        relativenumber = false;
        scrolloff = 4;
        shiftround = true;
        shiftwidth = 2;
        showmode = false;
        sidescrolloff = 8;
        signcolumn = "yes";
        smartcase = true;
        smartindent = true;
        splitbelow = true;
        splitkeep = "screen";
        splitright = true;
        tabstop = 2;
        termguicolors = true;
        timeoutlen = 500;
        undofile = true;
        undolevels = 10000;
        updatetime = 200;
        virtualedit = "block";
        wildmode = "longest:full,full";
        winminwidth = 5;
        wrap = true;
        winborder = "rounded";
        modeline = false;
        sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions";
        autocomplete = false;
        completeopt = "popup,nearest";
      };
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [ nixd ];
        programs.nixvim = {
          enable = true;
          nixpkgs.config = {
            allowUnfree = true;
            allowBroken = false;
          };
          globals = {
            mapleader = lib.mkForce settings.leaderKey;
          };
          viAlias = true;
          vimAlias = true;
          opts =
            if settings.options.useRecommendation then
              recommendedOptions // settings.options.extends
            else
              settings.options.extends;
          keymaps = [
            (mkKeymap "<leader>q" "<cmd>quitall<cr>" "Quit Neovim")
            (mkKeymap "<leader>wl" "<cmd>wincmd l<cr>" "󰖟 Move to right window")
            (mkKeymap "<leader>wh" "<cmd>wincmd h<cr>" "󰖞 Move to left window")
            (mkKeymap "<leader>wj" "<cmd>wincmd j<cr>" "󰖝 Move to down window")
            (mkKeymap "<leader>wk" "<cmd>wincmd k<cr>" "󰖜 Move to up window")
            (mkKeymap "<esc>" "<cmd>noh<cr>" "󰅂 Clear search highlight")
            # Native LSP actions
            (mkKeymap "<leader>la" "<cmd>lua vim.lsp.buf.code_action()<cr>" "󰌵 Code Action")
            (mkKeymap "<leader>ln" "<cmd>lua vim.lsp.buf.rename()<cr>" "󰑕 Rename Symbol")
            (mkKeymap "<leader>lh" "<cmd>lua vim.lsp.buf.signature_help()<cr>" "󰘥 Signature Help")
          ];
          dependencies.ripgrep.enable = true;
          lsp = {
            servers = {
              nixd = {
                enable = true;
                package = pkgs.nixd;
              };
              statix.enable = true;
            };
          };
          extraConfigLuaPost = ''
            -- nixd raises noisy "textDocument/documentHighlight failed: cannot
            -- find variable on given node" stderr lines whenever the cursor
            -- sits on a non-variable token. Disable the capability so neovim
            -- stops asking.
            vim.api.nvim_create_autocmd("LspAttach", {
              callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.name == "nixd" then
                  client.server_capabilities.documentHighlightProvider = false
                end
              end,
            })
          '';
        };
      })
    ];
}
