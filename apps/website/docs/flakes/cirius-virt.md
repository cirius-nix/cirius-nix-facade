---
title: cirius-virt
sidebar_position: 7
description: Podman and OCI containers, a virtualisation base with libvirt, and EDID-backed virtual displays.
---

# cirius-virt

Virtualisation for a workstation: a libvirt/QEMU base that is simply on, OCI
containers managed through Podman with declarative instances, and the display
plumbing needed to drive virtual monitors. Containers are declared as data —
each entry becomes an OCI container plus the tmpfiles rule that creates its data
directory.

| | |
| --- | --- |
| Namespace | `cnix-virt` |
| Module classes | `home`, `nixos` |
| External inputs | `cirius-lib` |
| Options | 25 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-virt.nixosModules.default ];

  cnix-virt.container = {
    enable = true;
    containers.postgres.instances.main = {
      enable = true;
      image = "docker.io/library/postgres:17";
      address = "127.0.0.1:5432";
      dataDir = "/var/lib/postgres-main";
    };
  };
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | *(always applies)* | Container registry config |
| `default` | nixos | *(always applies)* | libvirt/virt-manager base, recommended packages |
| `container` | nixos | `cnix-virt.container.enable` | Podman, OCI containers |
| `virt-desktop` | nixos | `cnix-virt.virt-desktop.enable` | EDID firmware and virtual outputs |

### `home/default` — container registry

Always applies. Writes `~/.config/containers/registries.conf` so unqualified image
names resolve against your registry instead of Docker Hub — useful when half your
images come from a private registry.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-virt.containerRegistry` | `str` | `"docker.io"` | The container registry to be used for unqualified image names. | Written as `unqualified-search-registries` in `containers/registries.conf`. |

### `nixos/default` — virtualisation base

Always applies. Enables `programs.virt-manager`, `virtualisation.libvirtd`, and
QEMU's software TPM, so a machine can run VMs without further configuration;
`useRecommendedPackages` adds `distrobox` and `quickemu` for containerised
distros and quick throwaway VMs.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-virt.useRecommendedPackages` | `bool` | `false` | Whether to use the recommended packages for virtualisation. | Installs `distrobox` and `quickemu`. |

### `nixos/container` — Podman and OCI containers

**Enable:** `cnix-virt.container.enable`

Installs `buildah`, `skopeo`, `pods`, and `podman-compose`, then turns on Podman
with the Docker socket and compatibility layer enabled and weekly auto-pruning.
Declared containers become `virtualisation.oci-containers.containers.<name>`
entries, with a `systemd.tmpfiles.rules` entry creating each data directory at
the right mode and ownership, and a bind address of the form
`<address>` with the service's port appended.

Dockhand additionally gets a unit ordered after the Podman socket with a restart
policy — the one place the module uses `mkForce`, because the container must
outlive socket restarts.

`dockhand` and each PostgreSQL instance share the same submodule type
(`containers.dockhand` and `containers.postgres.instances.<name>`), so the fields
below are identical in both places. Data directories fall back to
`/var/lib/dockhand` and `/var/lib/postgres-<name>`.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-virt.container.enable` | `bool` | `false` | Whether to enable the container module | Enables Podman/OCI support and the container tooling. |
| `cnix-virt.container.containers.dockhand` | `submodule` | `{ enable = false; image = "fnsys/dockhand:…"; address = "127.0.0.1:2000"; environmentFiles = [ ]; dataDir = "/var/lib/dockhand"; }` | Configuration for the Dockhand container | Configures the single Dockhand container. |
| `cnix-virt.container.containers.postgres.enable` | `bool` | `false` | Whether to enable the PostgreSQL container module | Enables PostgreSQL container instances. |
| `cnix-virt.container.containers.postgres.instances` | `attrsOf <submodule>` | `{ }` | Instances of PostgreSQL containers | Declares named PostgreSQL instances. |
| `<container>.enable` | `bool` | `false` | Whether to enable the container | Deploys the container and its tmpfiles rule. |
| `<container>.image` | `nullOr str` | — | Container image to use | Image reference for the container. |
| `<container>.address` | `str` | — | Address to bind the container to | Bind address; the service port (3000 for Dockhand, 5432 for PostgreSQL) is appended. |
| `<container>.environmentFiles` | `listOf str` | `[ ]` | List of environment files to pass to the container | Environment files handed to the container. |
| `<container>.dependsOn` | `listOf str` | `[ ]` | List of containers to depend on | Ordering between containers. |
| `<container>.dataDir` | `nullOr str` | — | Data directory for the container | Persistent data directory, created by tmpfiles; falls back to the `/var/lib/…` default. |
| `<container>.networks` | `listOf str` | `[ ]` | List of networks to connect the container to | Networks attached to the container. |

### `nixos/virt-desktop` — virtual displays

**Enable:** `cnix-virt.virt-desktop.enable`

Packages custom EDID files from `settings.dir` into a derivation installed under
`$out/lib/firmware/edid/`, then declares each entry as a
`hardware.display.outputs.<name>` with its mode. This is what makes a headless
machine present a monitor at a chosen resolution — for streaming, remote desktop,
or GPU passthrough setups.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-virt.virt-desktop.enable` | `bool` | `false` | Whether to enable virtual desktop support. | Enables EDID packaging and virtual displays. |
| `cnix-virt.virt-desktop.settings.dir` | `path` | — | Directory containing custom EDID files. | Source directory for the EDID firmware files. |
| `cnix-virt.virt-desktop.settings.edids` | `attrsOf <submodule>` | `{ }` | Attributes of EDID files to be used for virtual displays. | Each attribute is an EDID file, keyed by filename. |
| `…edids.<name>.name` | `str` | — | Name of the EDID file. | Output name used for the virtual display. |
| `…edids.<name>.mode` | `str` | — | Display mode for the EDID. | Mode assigned to the output. |

## Notes

- The `default` modules in both classes apply unconditionally; only `container`
  and `virt-desktop` are enable-gated.
- PostgreSQL instances and Dockhand share one submodule type, so any field listed
  as `<container>.*` applies to both paths.
- `image` and `dataDir` are declared nullable without a default, so NixOS reports
  them as unset until you provide a value; the module's fallbacks only apply to
  the derived data directory.
