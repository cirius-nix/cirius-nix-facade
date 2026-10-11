{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ namespace "settings" "hostName" ] [ "networking" "hostName" ])
  ];
  options.${namespace} =
    let
      inherit (lib.${namespace}) cnix-lib;
    in
    {
      enable = cnix-lib.mkBoolOpt {
        description = "Enable networking tools.";
      };
      settings = {
        vpn = {
          enable = cnix-lib.mkBoolOpt {
            description = "Enable VPN support.";
          };
        };
      };
    };

  config =
    let
      inherit (config.${namespace}) enable settings;
      inherit (settings) vpn;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        services = {
          openssh.enable = true;
          caddy.enable = true;
        };
      })
      (lib.mkIf (enable && vpn.enable) {
        services.tailscale = {
          enable = true;
        };
      })
    ];
}
