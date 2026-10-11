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
        hosts = cnix-lib.mkAttrsOpt {
          ofType =
            with lib.types;
            listOf (submodule {
              options.localDomain = cnix-lib.mkStrOpt {
                description = "Local domain for the host.";
              };
              options.upstream = cnix-lib.mkStrOpt {
                description = "Upstream for the host.";
              };
              options.extraConfig = cnix-lib.mkPrimOpt lib.types.lines {
                default = [ ];
                description = "Extra config for the host.";
              };
            });
          default = { };
          description = "Hostnames for the system.";
        };
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
      # setup hosts and reverse proxy for caddy
      (lib.mkIf enable {
        networking.hosts = lib.mapAttrs' (name: hostNames: {
          inherit name;
          value = lib.map (x: x.localDomain) hostNames;
        }) settings.hosts;

        services.caddy.virtualHosts =
          let
            mkVirtualHost =
              site:
              lib.nameValuePair site.localDomain {
                extraConfig = ''
                  reverse_proxy ${site.upstream}
                  ${site.extraConfig}
                '';
              };

            mkVirtualHosts = sites: lib.listToAttrs (map mkVirtualHost sites);

            mergeVirtualHosts =
              acc: _: sites:
              acc // mkVirtualHosts sites;

            virtualHosts = lib.foldlAttrs mergeVirtualHosts { } settings.hosts;
          in
          virtualHosts;
      })

      (lib.mkIf (enable && vpn.enable) {
        services.tailscale = {
          enable = true;
        };
      })
    ];
}
