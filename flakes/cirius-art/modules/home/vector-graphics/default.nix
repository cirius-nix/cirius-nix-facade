{
  config,
  pkgs,
  namespace,
  lib,
  ...
}:
{
  options.${namespace}.vector-graphics = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable vector graphic tools.";
    };
  };

  config =
    let
      inherit (config.${namespace}.vector-graphics) enable;
    in
    lib.mkIf enable {
      home.packages = with pkgs; [
        inkscape
        imagemagick
        gimp
        blender
      ];
    };
}
