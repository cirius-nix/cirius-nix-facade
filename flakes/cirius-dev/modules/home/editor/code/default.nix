{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.editor.code = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable VSCode editor.";
    };
  };

  config =
    let
      inherit (config.${namespace}.editor.code) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        programs.vscode = {
          enable = true;
          package = pkgs.vscode.fhs;
        };
      })
    ];
}
