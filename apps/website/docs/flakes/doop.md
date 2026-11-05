---
title: Doop self-hosting
sidebar_position: 8
---

# Doop self-hosting

Run Doop in a Podman OCI container through `cirius-virt`:

```nix
{
  imports = [ inputs.cirius-virt.nixosModules.default ];
  cnix-virt.container.containers.doop.enable = true;
}
```

Open `http://localhost:4400` after rebuilding. This enables the container base
automatically. Remove `cnix-dev.doop.enable` from Home Manager; the desktop
package and module have been removed in favour of the self-hosted browser app.

| Option under `cnix-virt.container.containers.doop` | Default | Purpose |
| --- | --- | --- |
| `enable` | `false` | Run the self-hosted application. |
| `image` | `null` | Use a prebuilt image instead of building the pinned upstream Dockerfile. |
| `address` | `"127.0.0.1:4400"` | Host binding for container port 4400. |
| `publicUri` | `"http://localhost:4400"` | Canonical origin for authentication and agent connections. |
| `dataDir` | `"/var/lib/doop"` | Persistent embedded database and assets. |
| `environmentFiles` | `[ ]` | Runtime environment files for SMTP, model keys, or external PostgreSQL. |

Upstream publishes a [Dockerfile](https://github.com/kgoedecke/doop/blob/v0.13.0/Dockerfile)
and [Compose configuration](https://github.com/kgoedecke/doop/blob/v0.13.0/docker-compose.yml),
with no official prebuilt image specified. By default, a systemd service builds
`localhost/doop:0.13.0` from the pinned source before starting the container.
The first start needs network access to pull base images and install dependencies,
and can take several minutes. The source is hash-pinned; upstream base image tags
and downloaded dependencies follow the upstream Dockerfile.

The single instance uses embedded PostgreSQL (PGlite). Its database and local
uploads persist under the mounted data directory. Authentication and credential
encryption keys are generated once at runtime and kept outside the Nix store.
The keys live in `/var/lib/doop-secrets/environment` (root-only, mode 600),
separate from the container volume. Back up both the data directory and that
secret file with the service stopped. Removing the module does not delete them.

For a reverse proxy, set `publicUri` to its external origin and forward HTTP and
WebSocket traffic to the local port. No firewall port is opened automatically.
The upstream [environment reference](https://github.com/kgoedecke/doop/blob/v0.13.0/.env.example)
describes SMTP, signup restrictions, external databases, and optional model keys.
Without SMTP, signup is open and auth emails are logged. Connect agents through
the self-hosted instance's **Connect AI** screen.

Inspect startup with `journalctl -u doop-image -u podman-doop -b` and check
`curl --fail http://localhost:4400/healthz`. Configuration evaluation alone does
not prove that the initial image build or application startup has completed.
