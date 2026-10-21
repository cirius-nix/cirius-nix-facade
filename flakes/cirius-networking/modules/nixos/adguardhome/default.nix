{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.adguardhome;
  dns = config.services.adguardhome.settings.dns;
  bindAddress = builtins.head dns.bind_hosts;
  address =
    if bindAddress == "0.0.0.0" then
      "127.0.0.1"
    else if bindAddress == "::" then
      "::1"
    else
      bindAddress;
  endpoint =
    if dns.port == 53 then
      address
    else
      "${if lib.hasInfix ":" address then "[${address}]" else address}:${toString dns.port}";
in
{
  options.${namespace}.adguardhome = {
    enable = lib.mkEnableOption "local AdGuard Home DNS filtering";
    useAsSystemResolver = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Route host DNS through AdGuard using systemd-resolved. Disable this when another service owns host DNS.";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.services.adguardhome.serviceConfig.StateDirectoryMode = lib.mkDefault "0700";
        services.adguardhome = {
          enable = true;
          mutableSettings = lib.mkDefault false;
          openFirewall = lib.mkDefault false;
          settings = {
            http.address = lib.mkDefault "127.0.0.1:3000";
            # The unauthenticated administration UI is local-only by default.
            users = lib.mkDefault [ ];
            dns = {
              bind_hosts = lib.mkDefault [ "127.0.0.2" ];
              port = lib.mkDefault 53;
              upstream_dns = lib.mkDefault [ "https://dns.quad9.net/dns-query" ];
              bootstrap_dns = lib.mkDefault [
                "9.9.9.9"
                "149.112.112.112"
              ];
              fallback_dns = lib.mkDefault [ ];
              # Do not forward private reverse queries back into our own host resolver.
              use_private_ptr_resolvers = lib.mkDefault false;
            };
            filtering = {
              protection_enabled = lib.mkDefault true;
              filtering_enabled = lib.mkDefault true;
              blocking_mode = lib.mkDefault "nxdomain";
            };
            filters = lib.mkDefault [
              {
                enabled = true;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                id = 1;
              }
            ];
            dhcp.enabled = lib.mkDefault false;
            querylog.enabled = lib.mkDefault false;
            statistics.enabled = lib.mkDefault false;
          };
        };
      }
      (lib.mkIf cfg.useAsSystemResolver {
        services.resolved = {
          enable = true;
          settings.Resolve = {
            DNS = lib.mkDefault [ endpoint ];
            Domains = lib.mkDefault [ "~." ];
            FallbackDNS = lib.mkDefault [ ];
          };
        };
        warnings = lib.optional config.services.cloudflare-warp.enable "cnix-net.adguardhome: set WARP to tunnel_only before activation so it does not compete for host DNS. The facade does not change WARP registration or runtime mode.";
      })
    ]
  );
}
