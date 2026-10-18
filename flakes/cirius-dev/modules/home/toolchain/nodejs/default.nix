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
      description = "Enable Node.js toolchain with Oxc linting and formatting.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.nodejs) enable;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          nodejs
          (lib.hiPrio pkgs.corepack)
          typescript
          typescript-language-server
          oxlint
          oxfmt
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
              oxlint = {
                enable = true;
                package = pkgs.oxlint;
                packageFallback = true;
                config = {
                  cmd = [
                    "oxlint"
                    "--lsp"
                  ];
                };
              };
            };
          };
          formatter = {
            fileTypes = {
              javascript = [ "oxfmt" ];
              javascriptreact = [ "oxfmt" ];
              typescript = [ "oxfmt" ];
              typescriptreact = [ "oxfmt" ];
              json = [ "oxfmt" ];
              jsonc = [ "oxfmt" ];
              css = [ "oxfmt" ];
              scss = [ "oxfmt" ];
              html = [ "oxfmt" ];
              yaml = [ "oxfmt" ];
            };
            tools.oxfmt.command = "oxfmt";
          };
          tests.adapters = {
            jest.enable = true;
            vitest.enable = true;
          };
        };
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = [ pkgs.vscode-extensions.oxc.oxc-vscode ];
          userSettings = {
            "oxc.enable.oxlint" = true;
            "oxc.enable.oxfmt" = true;
            # Clear nixpkgs' absolute defaults to allow project and PATH discovery.
            "oxc.path.oxlint" = "";
            "oxc.path.oxfmt" = "";
            "editor.codeActionsOnSave"."source.fixAll.oxc" = "explicit";
          }
          //
            lib.genAttrs
              [
                "[javascript]"
                "[javascriptreact]"
                "[typescript]"
                "[typescriptreact]"
                "[json]"
                "[jsonc]"
                "[css]"
                "[scss]"
                "[html]"
                "[yaml]"
              ]
              (_: {
                "editor.defaultFormatter" = "oxc.oxc-vscode";
                "editor.formatOnSave" = true;
              });
        };
      })
    ];
}
