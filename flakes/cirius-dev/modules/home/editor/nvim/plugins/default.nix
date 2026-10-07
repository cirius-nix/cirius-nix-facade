{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "formatter" "fileTypes" ]
      [ "programs" "nixvim" "plugins" "conform-nvim" "settings" "formatters_by_ft" ]
    )
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "formatter" "tools" ]
      [ "programs" "nixvim" "plugins" "conform-nvim" "settings" "formatters" ]
    )
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "session" "excludeFileTypes" ]
      [
        "programs"
        "nixvim"
        "plugins"
        "auto-session"
        "settings"
        "bypass_save_filetypes"
      ]
    )
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "tests" "adapters" ]
      [ "programs" "nixvim" "plugins" "neotest" "adapters" ]
    )
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "completion" "sources" ]
      [
        "programs"
        "nixvim"
        "plugins"
        "blink-cmp"
        "settings"
        "sources"
        "default"
      ]
    )
    (lib.mkAliasOptionModule
      [ namespace "editor" "nvim" "settings" "completion" "providers" ]
      [
        "programs"
        "nixvim"
        "plugins"
        "blink-cmp"
        "settings"
        "sources"
        "providers"
      ]
    )
  ];

  options.${namespace}.editor.nvim.plugins = { };

  config =
    let
      inherit (lib.${namespace}.nvim) mkKeymap mkRaw;

      inherit (config.${namespace}.editor.nvim) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        programs.nixvim.extraPackages = with pkgs; [
          fd
          ripgrep
          git
          trash-cli
          ripgrep
        ];

        programs.nixvim.keymaps = [
          (mkKeymap "<leader>e" "<cmd>lua snacks_explorer_focus_or_close()<cr>" " 󰙅 Explorer")

          (mkKeymap "<leader>f" "<nop>" {
            mode = [
              "n"
              "x"
            ];
            options = {
              silent = true;
              nowait = true;
              desc = "  Finder";
            };
          })
          # Find via Snacks picker
          (mkKeymap "<leader>ff" "<cmd>lua Snacks.picker.files()<cr>" " Find files")
          (mkKeymap "<leader>fg" "<cmd>lua Snacks.picker.grep()<cr>" "󰱼 Live grep")
          (mkKeymap "<leader>fw" "<cmd>lua Snacks.picker.grep_word()<cr>" "󰱼 Grep word")
          (mkKeymap "<leader>fb" "<cmd>lua Snacks.picker.buffers()<cr>" "󰈙 Buffers")
          (mkKeymap "<leader>fh" "<cmd>lua Snacks.picker.help()<cr>" "󰋖 Help tags")
          (mkKeymap "<leader>f/" "<cmd>lua Snacks.picker.resume()<cr>" "󰁯 Resume picker")
          # Find via Grug-Far
          (mkKeymap "<leader>fs" "<cmd>lua require('grug-far').open()<cr>" " 󰛔 Search & replace (project)")
          (mkKeymap "<leader>fs" "<cmd>lua require('grug-far').with_visual_selection()<cr>" {
            mode = [ "x" ];
            options = {
              silent = true;
              nowait = true;
              desc = " 󰛔 Replace visual selection";
            };
          })

          # LSP navigation via Snacks picker
          (mkKeymap "<leader>ld" "<cmd>lua Snacks.picker.lsp_definitions()<cr>" "󰊕 LSP Definition")
          (mkKeymap "<leader>lD" "<cmd>lua Snacks.picker.lsp_declarations()<cr>" "󰳽 LSP Declaration")
          (mkKeymap "<leader>lr" "<cmd>lua Snacks.picker.lsp_references()<cr>" "󰈇 LSP References")
          (mkKeymap "<leader>li" "<cmd>lua Snacks.picker.lsp_implementations()<cr>" "󰡱 LSP Implementation")
          (mkKeymap "<leader>lt" "<cmd>lua Snacks.picker.lsp_type_definitions()<cr>" "󰜁 LSP Type Definition")
          (mkKeymap "<leader>ls" "<cmd>lua Snacks.picker.lsp_symbols()<cr>" "󰓹 Document Symbols")
          # LSP calls via Snacks picker
          (mkKeymap "<leader>lc" "<nop>" "󰃷 Calls")
          (mkKeymap "<leader>lci" "<cmd>lua Snacks.picker.lsp_incoming_calls()<cr>" "󰃷 Incoming Calls")
          (mkKeymap "<leader>lco" "<cmd>lua Snacks.picker.lsp_outgoing_calls()<cr>" "󰃶 Outgoing Calls")
          # Diagnostics and lists via Trouble
          (mkKeymap "<leader>lx" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "󰅚 Buffer Diagnostics")

          # Tests
          (mkKeymap "<leader>t" "<nop>" "󰙨 Tests")
          (mkKeymap "<leader>tt" "<cmd>lua require('neotest').run.run()<cr>" "󰙨 Run nearest test")
          (mkKeymap "<leader>tf" "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>"
            "󰈙 Run test file"
          )
          (mkKeymap "<leader>ta" "<cmd>lua require('neotest').run.run(vim.uv.cwd())<cr>" "󰙨 Run all tests")
          (mkKeymap "<leader>tl" "<cmd>lua require('neotest').run.run_last()<cr>" "󰑓 Run last test")
          (mkKeymap "<leader>ts" "<cmd>lua require('neotest').summary.toggle()<cr>" "󰮫 Toggle test summary")
          (mkKeymap "<leader>to" "<cmd>lua require('neotest').output.open({ enter = true })<cr>"
            "󰍩 Show test output"
          )
          (mkKeymap "<leader>tp" "<cmd>lua require('neotest').output_panel.toggle()<cr>"
            "󰆍 Toggle test output panel"
          )
          (mkKeymap "<leader>tw" "<cmd>lua require('neotest').watch.toggle(vim.fn.expand('%'))<cr>"
            "󰂚 Watch test file"
          )
          (mkKeymap "<leader>tx" "<cmd>lua require('neotest').run.stop()<cr>" "󰓛 Stop test")
        ];

        programs.nixvim.extraConfigLua = ''
          snacks_explorer_focus_or_close = function()
            local pickers = Snacks.picker.get({ source = "explorer" }) or {}

            for _, picker in ipairs(pickers) do
              if picker and not picker.closed then
                local ft = vim.bo.filetype

                if ft:match("^snacks_picker") then
                  picker:close()
                else
                  picker:focus("list", { show = true })
                end

                return
              end
            end

            Snacks.explorer()
          end
        '';

        programs.nixvim.plugins = {
          snacks = {
            enable = true;
            autoLoad = true;
            callSetup = true;
            settings = {
              animate.enabled = true;
              input.enabled = true;
              notifier = {
                enabled = true;
                timeout = 3000;
                style = "compact";
              };
              bigfile.enabled = true;
              scroll = {
                enabled = true;
                animate = {
                  duration = {
                    step = 10;
                    total = 200;
                  };
                  easing = "linear";
                };
                animate_repeat = {
                  delay = 100;
                  duration = {
                    step = 5;
                    total = 50;
                  };
                  easing = "linear";
                };
                filter.__raw = ''
                  function(buf)
                    return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= "terminal"
                  end
                '';
              };
              styles.b.completion = false;
              explorer = {
                enabled = true;
                replace_netrw = true;
                trash = true;
              };
              picker = {
                enabled = true;
                ui_select = true;
                layout = {
                  cycle = true;
                  preset = "default";
                };
                matcher = {
                  fuzzy = true;
                  smartcase = true;
                  ignorecase = true;
                  filename_bonus = true;
                };
                sources = {
                  files = {
                    hidden = false;
                    ignored = false;
                  };
                  grep = {
                    hidden = false;
                    ignored = false;
                  };
                  explorer = {
                    hidden = false;
                    ignored = false;
                    follow_file = true;
                    focus = "list";
                    auto_close = false;
                    tree = true;
                    watch = true;
                    diagnostics = true;
                    diagnostics_open = false;
                    git_status = true;
                    git_status_open = false;
                    git_untracked = true;
                    layout = {
                      preset = "sidebar";
                      preview = false;
                    };
                    formatters = {
                      file.filename_only = true;
                      severity.pos = "right";
                    };
                    win.list.keys = {
                      "o" = "confirm";
                      "s" = "explorer_open";
                      "l" = "confirm";
                      "h" = "explorer_close";
                      "Z" = "explorer_close_all";
                      "a" = "explorer_add";
                      "d" = "explorer_del";
                      "r" = "explorer_rename";
                      "c" = "explorer_copy";
                      "m" = "explorer_move";
                      "p" = "explorer_paste";
                      "u" = "explorer_update";
                      "y" = mkRaw ''{ "explorer_yank", mode = { "n", "x" } }'';
                      "/" = "picker_grep";
                      "." = "explorer_focus";
                      "I" = "toggle_ignored";
                      "H" = "toggle_hidden";
                      "P" = "toggle_preview";
                      "]g" = "explorer_git_next";
                      "[g" = "explorer_git_prev";
                      "]d" = "explorer_diagnostic_next";
                      "[d" = "explorer_diagnostic_prev";
                      "]w" = "explorer_warn_next";
                      "[w" = "explorer_warn_prev";
                      "]e" = "explorer_error_next";
                      "[e" = "explorer_error_prev";
                      "<Esc>" = "close";
                    };
                  };
                };
                win = {
                  input.keys."<Esc>" = mkRaw ''{ "close", mode = { "n", "i" } }'';
                  list.keys."<Esc>" = "close";
                };
              };
            };
          };
          mini = {
            enable = true;
            modules = {
              comment = { };
              pairs = { };
            };
          };
          conform-nvim = {
            enable = true;
            autoInstall.enable = false;
            settings = {
              formatters_by_ft = {
                nix = [ "nixfmt" ];
                "_" = [
                  "trim_whitespace"
                  "trim_newlines"
                ];
              };
              formatters = {
                nixfmt.command = "nixfmt";
              };
              default_format_opts = {
                lsp_format = "never";
                timeout_ms = 1000;
              };
              notify_on_error = true;
              notify_no_formatters = false;
              format_on_save = {
                timeout_ms = 1000;
                # we have formatter so no need lsp format anymore.
                # can set to "falback" "never"
                lsp_format = "never";
              };
            };
          };
          none-ls.enable = true;
          nix-develop.enable = true;
          trouble = {
            enable = true;
            settings = {
              auto_close = true;
              focus = true;
            };
          };
          grug-far = {
            enable = true;
            settings = {
              engine = "ripgrep";
              engines = {
                ripgrep = {
                  path = "rg";
                  showReplaceDiff = true;
                };
              };
            };
          };
          auto-session = {
            enable = true;
            settings = {
              bypass_save_filetypes = [ "snacks_picker_list" ];
            };
          };
          neotest = {
            enable = true;
            settings = {
              floating.border = "rounded";
              output.open_on_run = "short";
              quickfix = {
                enabled = true;
                open = false;
              };
              summary.open = "botright vsplit | vertical resize 50";
            };
          };
          web-devicons.enable = true;
          which-key.enable = true;
          treesitter = {
            enable = true;
            package = pkgs.vimPlugins.nvim-treesitter;
            highlight.enable = true;
            indent.enable = true;
            folding.enable = false;
            nixGrammars = true;
          };
          lualine = {
            enable = true;
            settings = {
              options = {
                globalstatus = true;
                theme = "auto";
                icons_enabled = true;
              };
            };
          };
          luasnip.enable = true;
          blink-cmp = {
            enable = true;
            settings = {
              appearance = {
                use_nvim_cmp_as_default = true;
                nerd_font_variant = "normal";
                kind_icons = {
                  claude = "󰋦";
                  openai = "󱢆";
                  codestral = "󱎥";
                  gemini = "";
                  Groq = "";
                  Openrouter = "󱂇";
                  Ollama = "󰳆";
                  "Llama.cpp" = "󰳆";
                  Deepseek = "";
                };
              };
              snippets = {
                preset = "luasnip";
              };
              sources = {
                default = [
                  "lsp"
                  "path"
                  "snippets"
                  "buffer"
                ];
                providers = {
                  lsp.score_offset = lib.mkDefault 100;
                  snippets.score_offset = lib.mkDefault 85;
                  path.score_offset = lib.mkDefault 80;
                  buffer.score_offset = lib.mkDefault 75;
                };
              };
              keymap = {
                preset = "super-tab";
                "<cr>" = [
                  "select_and_accept"
                  "fallback"
                ];
                "<Tab>" = [
                  "snippet_forward"
                  "select_next"
                  "fallback"
                ];
                "<S-Tab>" = [
                  "snippet_backward"
                  "select_prev"
                  "fallback"
                ];
              };
              fuzzy.implementation = "prefer_rust_with_warning";
              signature.enabled = true;
              completion = {
                trigger.prefetch_on_insert = false;
                list = {
                  selection = {
                    preselect = true;
                    auto_insert = true;
                  };
                };
                keyword.range = "full";
                documentation = {
                  auto_show = true;
                  auto_show_delay_ms = 200;
                };
                ghost_text.enabled = true;
              };
            };
          };
        };
      })
    ];
}
