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
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [ nix-tree ];
        programs.nix-index = {
          enable = true;
          enableFishIntegration = shell == "fish";
        };
      })
    ];
}
