{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.sprite = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable sprite support.";
    };
  };

  config =
    let
      inherit (config.${namespace}.sprite) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          aseprite
          ldtk
        ];
      })
    ];
}
