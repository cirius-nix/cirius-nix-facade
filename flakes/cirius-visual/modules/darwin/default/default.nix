{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
{
  options.${namespace}.useRecommendedFonts = lib.mkEnableOption "the recommended fonts";
  config = lib.mkIf config.${namespace}.useRecommendedFonts {
    fonts.packages = [
      pkgs.nerd-fonts.monaspace
      pkgs.ibm-plex
      (pkgs.callPackage ../../../packages/be-vietnam-pro { })
    ];
  };
}
