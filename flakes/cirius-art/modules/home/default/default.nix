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
      default = true;
      description = "Whether to use recommended packages for art.";
    };
  };

  config =
    let
      inherit (config.${namespace}) useRecommendedPackages;
    in
    lib.mkIf useRecommendedPackages {
      home.packages = with pkgs; [
        inkscape
        blender
        imagemagick
        krita
        pkgs.${namespace}.comfy-desktop
      ];
    };
}
