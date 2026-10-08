{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.android = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Android toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.android) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          android-studio
        ];
      })
    ];
}
