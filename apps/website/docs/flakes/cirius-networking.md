---
title: cirius-networking
sidebar_position: 5
description: Local AdGuard Home filtering, SSH, Caddy reverse proxies, and optional Tailscale.
---

# cirius-networking

Import the default NixOS module, then enable the concern you need. AdGuard Home
works independently of the SSH/Caddy preset. All enable flags default to `false`.

## Local DNS filtering

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-networking.nixosModules.default ];
  cnix-net.adguardhome.enable = true;
}
```

This enables a declarative AdGuard Home configuration, a basic ad/tracker filter
list, and host DNS routing through systemd-resolved. It does not require the
AdGuard setup wizard or additional flake inputs.

| Facade option | Default | Effect |
| --- | --- | --- |
| `cnix-net.adguardhome.enable` | `false` | Enable the local filtering preset. |
| `cnix-net.adguardhome.useAsSystemResolver` | `true` | Route host DNS through AdGuard using systemd-resolved. Set false to run the filtering service without changing host resolver configuration. |

The default DNS listener is `127.0.0.2:53`, separate from systemd-resolved's stub
and virtualization bridge addresses. The administration UI is at
[http://127.0.0.1:3000](http://127.0.0.1:3000). It has no login by default and is
bound only to loopback. Configure authentication before exposing it remotely.

The preset uses:

- Quad9 DNS over HTTPS, with explicit bootstrap IP addresses. It does not use
  the host resolver to bootstrap its own upstream server.
- The AdGuard DNS filter, downloaded at runtime and stored in service state.
  Initial download and updates require network access.
- Enabled protection and filter-list processing, with NXDOMAIN responses for
  blocked domains.
- Disabled DHCP, query logging, and statistics. No new firewall openings.
- Disabled private reverse-DNS forwarding to avoid a loop back to the host
  resolver. Private zones can use specific resolver routes.

Settings are declarative by default, so web UI changes reset on restart. Native
`services.adguardhome.mutableSettings = true` preserves changes to settings not
declared by Nix; declared values still win on restart.
Use `services.adguardhome.*` for advanced configuration; the facade does not
re-export its settings schema. For example:

```nix
services.adguardhome.settings.querylog.enabled = true;
```

Native listener address and port overrides also update the default
systemd-resolved endpoint. Native resolver settings remain available through
`services.resolved.*`. If upstream resolution or AdGuard fails, the preset does
not supply an unfiltered fallback resolver.

### WARP and VPN DNS

If Cloudflare WARP currently owns host DNS, switch it to traffic-only mode when
adopting the preset:

```sh
warp-cli mode tunnel_only
```

Run this on a registered client that supports the mode, immediately before
activating the consuming host configuration. WARP then carries traffic while
AdGuard filters DNS. The facade does not register WARP, change its runtime mode,
or alter tunnel routes. It emits a reminder when the NixOS WARP service is
enabled together with host resolver integration.

If another service must retain host DNS ownership:

```nix
cnix-net.adguardhome = {
  enable = true;
  useAsSystemResolver = false;
};
```

This mode runs AdGuard but does not filter host queries automatically.

With host integration enabled, NetworkManager uses systemd-resolved. The global
`~.` route sends ordinary queries to AdGuard; more-specific VPN/private domains
keep their own resolvers. A VPN that installs another catch-all `~.` route can
compete with this route, so configure that VPN's DNS policy rather than assuming
all queries are filtered. Applications using their own DNS-over-HTTPS can bypass
the system resolver.

### Virtualization and hotspot compatibility

AdGuard binds a specific loopback address. It does not replace libvirt dnsmasq,
Podman network DNS, or hotspot DHCP/DNS, and it does not intercept guest traffic.
This avoids wildcard port-53 conflicts and preserves VM/container service names.

Guests and containers keep the resolver supplied by their network. Whether
external queries are filtered depends on that resolver's upstream path. Do not
put the host's `127.0.0.2` directly in a guest or container: loopback addresses
refer to that guest or container. Custom networks and VPN policies can require
native DNS configuration.

## SSH, hosts, and reverse proxies

```nix
cnix-net = {
  enable = true;
  settings.hostName = "gateway";
  settings.hosts."127.0.0.1" = [
    { localDomain = "jellyfin.home.arpa"; upstream = "127.0.0.1:8096"; }
  ];
  settings.vpn.enable = true;
};
```

This existing preset enables SSH and Caddy. Each hosts-table key is an IP address;
its list entries supply local domain names and reverse-proxy targets. Tailscale
is enabled only when both the preset and its VPN option are enabled.

| Existing option | Default | Effect |
| --- | --- | --- |
| `cnix-net.enable` | `false` | Enable SSH, Caddy, and hosts/proxy generation. |
| `cnix-net.settings.hostName` | Native | Alias of `networking.hostName`. |
| `cnix-net.settings.hosts` | `{ }` | IP address to a list of host/proxy records. |
| `…hosts.<address>.*.localDomain` | Required per entry | Domain name for the hosts file and Caddy site. |
| `…hosts.<address>.*.upstream` | Required per entry | Reverse-proxy target. |
| `…hosts.<address>.*.extraConfig` | `""` | Extra Caddy site configuration. |
| `…hosts.<address>.*.proxyExtraConfig` | `""` | Extra reverse-proxy configuration. |
| `cnix-net.settings.vpn.enable` | `false` | Enable Tailscale with the SSH/Caddy preset. |

The default module imports all networking sibling modules. Consumers need only
one import. Existing hosts and proxy behavior is unchanged; the preset and VPN
flags now have disabled defaults instead of being required values.

## Development checks

From the repository root:

```sh
nix flake check path:./flakes/cirius-networking
nix build --impure --no-link --file flakes/cirius-networking/tests modules integration
```

Module checks cover disabled and enable-only configurations, native overrides,
service-only operation, and composition with `cirius-virt`. The VM test uses
local DNS/filter fixtures and tests host filtering, private DNS routing,
libvirt-network DHCP/DNS, rootful and rootless Podman, other DNS listeners,
external exposure, and restarts. It requires KVM. WARP and Tailscale production
services and public upstream connectivity are not exercised by the offline test.
