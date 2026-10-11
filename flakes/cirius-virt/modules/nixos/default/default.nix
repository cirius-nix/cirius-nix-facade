{
  config,
  namespace,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = builtins.attrValues (removeAttrs inputs.self.nixosModules [ "default" ]);
  options.${namespace} =
    let
      inherit (lib) cnix-lib;
    in
    {
      useRecommendedPackages = cnix-lib.mkBoolOpt {
        default = false;
        description = "Whether to use the recommended packages for virtualisation.";
      };
    };
  config =
    let
      inherit (config.${namespace}) useRecommendedPackages;
    in
    lib.mkMerge [
      {
        programs.virt-manager.enable = true;
        virtualisation = {
          libvirtd = {
            enable = true;
            qemu = {
              swtpm.enable = true;
            };
          };
        };
      }
      (lib.mkIf useRecommendedPackages {
        environment.systemPackages = with pkgs; [
          distrobox
          quickemu
        ];
      })
    ];
}
