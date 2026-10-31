{
  inputs,
  pkgs,
  namespace,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.self.homeModules.sprite
  ];

  options.${namespace} = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use recommended packages for art.";
    };
  };

  config =
    let
      inherit (config.${namespace}) useRecommendedPackages;
    in
    lib.mkIf useRecommendedPackages {
      home.packages =
        with pkgs;
        with pkgs.${namespace};
        [
          inkscape
          blender
          imagemagick
          krita
          freecad
          # our own packages
          comfy-desktop
          openpencil-cli
          openpencil-desktop
        ];
    };
}
