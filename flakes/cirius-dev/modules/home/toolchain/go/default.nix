{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.go = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Go toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.go) enable;
      inherit (config.${namespace}.editor) nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          go
          gopls
          delve
          golangci-lint
          goimports
          goreleaser
          go-tools
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          formatter = {
            fileTypes = {
              go = [ "goimports" ];
            };
            tools.goimports.command = "goimports";
          };
          tests.adapters.golang.enable = true;
          lsp = {
            servers.gopls = {
              enable = true;
              packageFallback = true;
              config = {
                cmd = [
                  "gopls"
                  "serve"
                ];
                settings = {
                  gopls = {
                    analyses = {
                      unusedparams = true;
                      shadow = true;
                    };
                    staticcheck = true;
                  };
                };
              };
            };
          };
        };
      })
    ];
}
