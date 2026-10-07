{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.nodejs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Node.js toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.nodejs) enable;
      inherit (config.${namespace}.editor) nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          nodejs
          (lib.hiPrio pkgs.corepack)
          typescript
          typescript-language-server
          vscode-langservers-extracted
          prettierd
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          lsp = {
            servers = {
              ts_ls = {
                enable = true;
                packageFallback = true;
                config = {
                  cmd = [
                    "typescript-language-server"
                    "--stdio"
                  ];
                };
              };
              eslint = {
                enable = true;
                packageFallback = true;
                config = {
                  cmd = [
                    "vscode-eslint-language-server"
                    "--stdio"
                  ];

                  settings = {
                    workingDirectory = {
                      mode = "auto";
                    };
                  };
                };
              };
            };
          };
          formatter = {
            fileTypes = {
              javascript = [ "prettierd" ];
              javascriptreact = [ "prettierd" ];
              typescript = [ "prettierd" ];
              typescriptreact = [ "prettierd" ];
              json = [ "prettierd" ];
              jsonc = [ "prettierd" ];
              css = [ "prettierd" ];
              scss = [ "prettierd" ];
              html = [ "prettierd" ];
              yaml = [ "prettierd" ];
            };
            tools.prettierd.command = "prettierd";
          };
          tests.adapters = {
            jest.enable = true;
            vitest.enable = true;
          };
        };
      })
    ];
}
