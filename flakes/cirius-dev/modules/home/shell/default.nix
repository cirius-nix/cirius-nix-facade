{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.shell = lib.mkOption {
    type =
      with lib.types;
      (enum [
        "bash"
        "zsh"
        "fish"
      ]);
    default = "fish";
    description = "Whether to use recommended shell packages.";
  };

  config =
    let
      inherit (config.${namespace}) shell;
    in
    lib.mkMerge [
      (lib.mkIf (shell == "bash") {
        programs.bash = {
          enable = true;
        };
      })

      (lib.mkIf (shell == "zsh") {
        programs.zsh = {
          enable = true;
        };
      })

      (lib.mkIf (shell == "fish") {
        programs.fish = {
          enable = true;
        };
      })
    ];
}
