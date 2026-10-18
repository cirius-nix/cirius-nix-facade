{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.markdown = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Markdown toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.markdown) enable;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          pandoc
          markdownlint-cli
          markdown-toc
          marksman
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          formatter = {
            fileTypes = {
              markdown = [
                "markdownlint"
              ];
            };
            tools.markdownlint.command = "markdownlint";
          };
          lsp.servers.marksman = {
            enable = true;
            packageFallback = true;
            config = {
              cmd = [
                "marksman"
                "server"
              ];
              filetypes = [
                "markdown"
                "markdown.mdx"
              ];
              root_markers = [
                ".marksman.toml"
                ".git"
              ];
            };
          };
        };
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = [ pkgs.vscode-extensions.davidanson.vscode-markdownlint ];
          userSettings."[markdown]" = {
            "editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave"."source.fixAll.markdownlint" = "explicit";
          };
        };
      })
    ];
}
