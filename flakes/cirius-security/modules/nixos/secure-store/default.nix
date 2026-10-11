{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.secure-store = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable secure store";
    };
    settings = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "secure-store";
        description = "The name of the secure store device.";
      };
      luksDevicePath = lib.mkOption {
        type = lib.types.str;
        default = null;
        description = "The path to the LUKS device, e.g. /dev/disk/by-uuid/...";
      };
      mountPoint = {
        fsType = lib.mkOption {
          type = lib.types.str;
          default = "ext4";
          description = "The filesystem type for the secure store.";
        };
        options = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Mount options for the secure store filesystem.";
        };
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.secure-store) enable settings;
      mountPointID = "/mnt/${settings.name}";
    in
    lib.mkMerge [
      (lib.mkIf enable {
        assertions = [
          {
            assertion = settings.luksDevicePath != null;
            message = "The LUKS device path must be specified when secure store is enabled.";
          }
          {
            assertion = settings.mountPoint.fsType != null;
            message = "The filesystem type for the secure store must be specified.";
          }
        ];
        # Register the LUKS device with the initrd
        boot.initrd.luks.devices.${settings.name} = {
          device = settings.luksDevicePath;
        };
        # Register the secure store filesystem to be mounted at boot
        fileSystems."${mountPointID}" = {
          device = "/dev/mapper/${settings.name}";
          inherit (settings.mountPoint) fsType options;
        };
      })
    ];
}
