{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = (with inputs; [ ]) ++ attrValues (removeAttrs inputs.self.nixosModules [ "default" ]);
  options.${namespace} = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use recommended packages for virt-manager and libvirt.";
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
        ];
      })
    ];
}
