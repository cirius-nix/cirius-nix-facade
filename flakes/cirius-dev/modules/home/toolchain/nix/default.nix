{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Nix toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.nix) enable;
      inherit (config.${namespace}) shell;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          nix-tree
          nixd
          nixfmt
          statix
        ];
        programs.nix-index = {
          enable = true;
          enableFishIntegration = shell == "fish";
        };
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          lsp.servers = {
            nixd = {
              enable = true;
              package = pkgs.nixd;
              packageFallback = true;
              config.settings.nixd.formatting.command = [ "nixfmt" ];
            };
            statix = {
              enable = true;
              packageFallback = true;
            };
          };
          formatter = {
            fileTypes.nix = [ "nixfmt" ];
            tools.nixfmt.command = "nixfmt";
          };
        };
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = [ pkgs.vscode-extensions.jnoortheen.nix-ide ];
          userSettings = {
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            "nix.serverSettings".nixd.formatting.command = [ "nixfmt" ];
            "[nix]" = {
              "editor.defaultFormatter" = "jnoortheen.nix-ide";
              "editor.formatOnSave" = true;
            };
          };
        };
      })
    ];
}
