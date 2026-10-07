{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.container = {
    enable = lib.mkOption {
      type = with lib.types; bool;
      default = false;
      description = "Enable container supports";
    };
  };
  config =
    let
      inherit (config.${namespace}) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable.enable {
        virtualisation = {
          containers.enable = true;
          oci-containers.backend = "podman";
          podman = {
            enable = true;
            dockerCompat = true;
            dockerSocket.enable = true;
            autoPrune = {
              enable = opts.podman.autoPrune;
              dates = "weekly";
            };
            defaultNetwork.settings = {
              dns_enabled = true;
            };
          };
        };
      })
    ];
}
