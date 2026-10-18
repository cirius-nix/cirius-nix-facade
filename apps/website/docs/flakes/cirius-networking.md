---
title: cirius-networking
sidebar_position: 5
description: One NixOS module that derives SSH, hostnames, and Caddy reverse proxies from a declarative hosts table.
---

# cirius-networking

Networking for a machine that serves things: SSH and Caddy are turned on, and
everything else is derived from a single declarative table of hosts. Each entry
becomes both a `networking.hosts` line and a Caddy virtual host with a
`reverse_proxy` block, so adding a service is one attribute rather than three
files.

| | |
| --- | --- |
| Namespace | `cnix-net` |
| Module classes | `nixos` |
| External inputs | `cirius-lib` |
| Options | 8 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-networking.nixosModules.default ];

  cnix-net = {
    enable = true;
    settings.hostName = "gateway";
    settings.hosts."jellyfin" = {
      localDomain = "jellyfin.home.arpa";
      upstream = "127.0.0.1:8096";
    };
    settings.vpn.enable = true;
  };
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | nixos | `cnix-net.enable` | SSH, Caddy, hosts table, optional Tailscale |

### `nixos/default` — hosts and reverse proxy

**Enable:** `cnix-net.enable`. Note that this option declares **no default**, so
it must be set explicitly — an unset value fails evaluation rather than silently
disabling the module.

When enabled it turns on `services.openssh` and `services.caddy`, builds
`networking.hosts` from `settings.hosts`, and generates a Caddy virtual host per
entry keyed by its `localDomain`, with a `reverse_proxy` block targeting
`upstream`. `extraConfig` is prepended to the site block and `proxyExtraConfig`
is inserted inside the proxy block, which is enough for headers, TLS, or
websocket tuning without abandoning the table.

`settings.hostName` is an alias of `networking.hostName`, so it sets the system
hostname rather than duplicating it.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-net.enable` | `bool` | — *(no default declared)* | Enable networking tools. | Turns on SSH and Caddy and enables host/proxy generation. |
| `cnix-net.settings.hostName` | `str` (alias of `networking.hostName`) | — | — | Sets the system hostname. |
| `cnix-net.settings.hosts` | `attrsOf (listOf <submodule>)` | `{ }` | Hostnames for the system. | Each attribute becomes a `networking.hosts` entry and a Caddy virtual host. |
| `…hosts.<name>.localDomain` | `str` | — | Local domain for the host. | The hostname added to `networking.hosts` and used as the Caddy site address. |
| `…hosts.<name>.upstream` | `str` | — | Upstream for the host. | Target of the generated `reverse_proxy` directive. |
| `…hosts.<name>.extraConfig` | `lines` | `""` | Extra config for the host. | Appended to the virtual host block. |
| `…hosts.<name>.proxyExtraConfig` | `lines` | `""` | Extra config for the reverse proxy. | Inserted inside the `reverse_proxy { … }` block. |
| `cnix-net.settings.vpn.enable` | `bool` | — | Enable VPN support. | Also enables `services.tailscale`. |

## Notes

- `cnix-net.enable`, `settings.vpn.enable`, and the per-host `localDomain` and
  `upstream` are built without a declared default, so NixOS treats them as
  required — set them explicitly.
- The module exports a small `lib/` output (`cnix-net.cnix-lib`) that re-exports
  the `cirius-lib` helpers for use inside the module; it is not intended for
  consumers.
- There are no packages or overlays in this flake.
