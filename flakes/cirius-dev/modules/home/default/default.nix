{
  config,
  inputs,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports =
    (with inputs; [
      nixvim.homeModules.default
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);

  options.${namespace} = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use recommended packages for nvim.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.${namespace}.useRecommendedPackages {
      home.packages = with pkgs; [
        bruno
        direnv
        devenv
        btop
      ];
      programs.direnv = {
        enable = true;
        config = {
          global = {
            hide_env_diff = true;
          };
        };
      };
      programs.devenv.enable = true;
    })
  ];
}
