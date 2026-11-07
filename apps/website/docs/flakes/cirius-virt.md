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
| Options | 35 |

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

Penpot deploys the full upstream stack from the
[official Docker compose file](https://help.penpot.app/technical-guide/getting-started/docker/)
as OCI containers: `penpot-frontend` (bound to `address`), `penpot-backend`,
`penpot-admin-console`, `penpot-mcp`, `penpot-exporter`, `penpot-postgres`,
`penpot-valkey`, and — unless `mailpit.enable = false` — a `penpot-mailpit`
SMTP catch-all bound to `mailpit.address`. The services reach each other by
name over the default Podman network. A `PENPOT_SECRET_KEY` is generated once
into `<dataDir>/penpot.env` (mode 600) on first activation; add more variables
to that file, or pass extra files via `environmentFiles`, to override it or to
configure an external SMTP provider. Data directories fall back to
`/var/lib/penpot` (`assets/` and `postgres/` inside it).

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-virt.container.containers.penpot` | — | — | Penpot container stack | See the fields below. |
| `…penpot.enable` | `bool` | `false` | Whether to enable the Penpot containers | Deploys the full Penpot stack. |
| `…penpot.version` | `str` | `"2.18"` | Penpot image tag to use for all Penpot services | Appended to every `penpotapp/*` image. |
| `…penpot.address` | `str` | `"127.0.0.1:9001"` | Address to bind the Penpot frontend to | Frontend port binding (`<address>:8080`). |
| `…penpot.publicUri` | `str` | `"http://localhost:9001"` | Public URI used to access Penpot | Passed as `PENPOT_PUBLIC_URI`. |
| `…penpot.dataDir` | `nullOr str` | — | Data directory for the Penpot containers | Persistent data; falls back to `/var/lib/penpot`. |
| `…penpot.environmentFiles` | `listOf str` | `[ ]` | Environment files for the secret-key services | Passed to backend, admin-console, and exporter, after the generated secret file. |
| `…penpot.flags` | `listOf str` | *upstream defaults* | Penpot feature flags passed via `PENPOT_FLAGS` | Joined with spaces; defaults match the official compose file. |
| `…penpot.telemetryEnabled` | `bool` | `true` | Whether to enable Penpot telemetry | Passed as `PENPOT_TELEMETRY_ENABLED`. |
| `…penpot.mailpit.enable` | `bool` | `true` | Whether to enable the Mailpit SMTP catch-all container | Deploys `penpot-mailpit` and points the backend SMTP at it. |
| `…penpot.mailpit.address` | `str` | `"127.0.0.1:8025"` | Address to bind the Mailpit web UI to | Mailpit web UI binding. |

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
- Penpot containers find each other by name on the default Podman network
  (DNS is enabled by the container module), so no extra networks are declared.
  Administrative tasks use the documented names, e.g.
  `podman exec -ti penpot-backend python3 manage.py create-profile`.

## Family media: Jellyfin and Immich

`cnix-virt.family-media` uses the upstream NixOS services, not a new application
or a second container stack. Jellyfin provides video/photo libraries and family
accounts; Immich provides private photo/video uploads, albums and mobile backup.

```nix
cnix-virt.family-media = {
  enable = true;
  jellyfin.libraryPaths = [ "/srv/family-media/Pictures" "/srv/family-media/Videos" ];
  immich.libraryPaths = [ "/srv/family-media/Pictures" "/srv/family-media/Videos" ];
};
```

Each service can be disabled with its `enable = false` option. Other settings
remain available through upstream `services.jellyfin` and `services.immich`.

### Storage and privacy

- Jellyfin state and configuration: `/var/lib/jellyfin`; cache:
  `/var/cache/jellyfin`.
- Immich uploads, generated media and built-in database backups:
  `/var/lib/immich`; machine-learning cache: `/var/cache/immich`.
- Native PostgreSQL uses its normal `/var/lib/postgresql` data directory, with
  VectorChord configured by NixOS. PostgreSQL and Redis use local Unix sockets.
- Keep these writable locations on a POSIX filesystem such as Btrfs/ext4 on an
  SSD. Do not put PostgreSQL on NTFS.
- Existing NTFS pictures/videos can be mounted read-only under `/srv`. Both
  services use separate system users, read-only library binds and required-mount
  dependencies. `/home` and the raw `/mnt` tree are hidden inside their sandboxes.
- Library paths must be outside `/home` and `/mnt`. Configure explicit bind
  mounts, rather than changing ownership or permissions on an entire disk.

NTFS mounted with `uid=1000,gid=100,umask=022` does not grant a dedicated Immich
user write access. Group membership or a simple bind mount cannot fix this.
Writable uploads intentionally stay on the SSD; the original NTFS content is
indexed in place and is not moved, renamed or deleted. Do not point Immich's
managed upload directory at an existing photo collection.

### First use and private networking

No firewall ports, Caddy routes, Tailscale sharing or public listeners are added.
Immich binds to `127.0.0.1:2283`. Jellyfin's network XML is patched before startup
to bind only `127.0.0.1`, disable IPv6 and disable UDP auto-discovery. Other XML
settings, including a previously customized HTTP port, are preserved. Its
normal initial URL is `http://127.0.0.1:8096`.

The first visit to each application's web UI creates its administrator. Do this
locally before adding family access; no default password or API key is created
in Nix. Then:

1. Add the configured `/srv/...` directories as Jellyfin libraries. Do not enable
   writing metadata beside the original files.
2. In Immich Administration, create an **External Library**, choose its owner,
   add the configured `/srv/...` import paths and scan. Directory mounts alone
   do not create an Immich library or grant every account access to it.
3. Create separate family accounts and share only intended libraries/albums.
4. Use Immich web/mobile uploads for new photos; these go to SSD storage. Jellyfin
   is the playback catalog, not a general-purpose upload service.

Remote family access requires a separately reviewed private route, such as a
Tailscale-only HTTPS reverse proxy with appropriate DNS/certificate trust. The
localhost URLs are not reachable from another phone/computer. Never expose a
first-run setup wizard publicly or assume `openFirewall = false` changes a
service's listening address.

Back up **both** Immich's database and its entire media directory, plus Jellyfin
state and original NTFS files. A second directory on the same machine/disk is
not disaster recovery. Test restoration before relying on phone backup alone.

### Validation

```sh
python3 flakes/cirius-virt/tests/private-network-test.py
nix-instantiate --eval --strict --json \
  --arg nixpkgs /path/to/pinned/nixpkgs \
  flakes/cirius-virt/tests/family-media-eval.nix
```

The tests cover opt-in/opt-out behavior, service users, network defaults, library
protection and XML creation/preservation/failure cases. They are evaluation/unit
tests, not a live upload/playback or filesystem test. Before enabling family
access, test an upload, external-library scan, video playback, read-only behavior,
and listeners (including Jellyfin's first-run setup stage) on the deployed host.
