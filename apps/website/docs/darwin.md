---
title: Apple Silicon macOS
sidebar_position: 3
---

# Apple Silicon macOS

Use nix-darwin for system configuration and Home Manager for the user tools.
Docker Desktop must already be installed. The facade does not install or start
Docker Desktop, migrate Linux data, or change your Docker context globally.

The [example consumer](https://github.com/cirius-nix/cirius-nix-facade/tree/main/examples/darwin)
uses local subflakes from a checkout. Change `cirius` and `/Users/cirius` to your
existing macOS account before using it. Keep existing state versions when adding
these modules to an established configuration. There is no root flake.

```sh
nix flake lock ./examples/darwin
nix build ./examples/darwin#darwinConfigurations.mac.system --no-link
sudo darwin-rebuild switch --flake ./examples/darwin#mac
```

The final command activates the configuration on the Mac; evaluation or build
does not activate it. Set up nix-darwin first if `darwin-rebuild` is not present.
In another repository, replace the local `path:` inputs with the usual
`github:cirius-nix/cirius-nix-facade/main?dir=flakes/<concern>` inputs, and make
them follow the host's `nixpkgs`. Import `cirius-dev.overlays.default` into
`nixpkgs.overlays`, as the example does, so the shared AI and project tools are
available to Home Manager.

## Supported modules

| Concern | Import on macOS | Coverage |
| --- | --- | --- |
| Dev | `homeModules.darwin` | Shell, Git CLI, Neovim, VS Code, portable toolchains, AI CLIs. Ghostty configuration only; install the native app separately. |
| Security | `homeModules.default` | SSH client, SOPS/age, SSH tunnels through launchd. Supply your own secret paths; Linux `/mnt/secure-store` paths do not apply. |
| Utils | `homeModules.darwin` | Syncthing through upstream launchd support, optional rebuild abbreviations. |
| Virt | `homeModules.darwin` | Docker Desktop Compose applications below. |
| Networking | `darwinModules.default` | Native Caddy reverse proxy through launchd. |
| Art | `homeModules.default` | ImageMagick. Linux desktop packages and sprite tools are skipped. |
| Office | `homeModules.default` | PDF CLI; the technical variant adds portable document tools. Linux GUI/research tools are skipped. |
| Visual | `darwinModules.default` | `cnix-visual.useRecommendedFonts` installs the fonts through nix-darwin. Optional `homeModules.darwin` configures Ghostty/Neovim themes when those modules are imported. |

Do not import the Linux dev/utils/visual aggregates on macOS. Do not import the
NixOS module graphs: Flatpak, KDE/GNOME, gaming, libvirt, EDID, Linux networking,
LUKS/firewall, runners and fcitx5-lotus stay on Linux. Native Android Studio,
Unity Hub and desktop AI clients can be installed separately. LaTeX keeps the
compiler/LSP on macOS and omits Zathura integration; C++ uses LLDB instead of GDB.

This target is `aarch64-darwin`; Intel support is outside this example.

## Local applications

Enable `cnix-virt.container.enable` and the desired
`cnix-virt.container.containers.<doop|penpot|dockhand>.enable` flags in Home Manager.
The example enables all three. Docker Desktop owns the Linux VM and the daemon.

```sh
# Open Docker Desktop first, then:
cnix-containers up
cnix-containers ps
cnix-containers config
cnix-containers logs
cnix-containers down
```

`up` builds Doop 0.13.0 from the pinned upstream source when the local image is
missing. Use `cnix-containers build` to rebuild it explicitly. Penpot uses 2.18.6
for all five images; Dockhand uses the ARM-capable normal image `5a3b1e8d`, not
the x86 baseline image. All services request `linux/arm64` and use
`restart: unless-stopped`. Docker Desktop must run again after reboot for those
policies to take effect. The facade does not add startup jobs for the stack.

| App | Direct local URL | Example HTTPS URL |
| --- | --- | --- |
| Doop | `http://localhost:4400` | `https://doop.home.arpa` |
| Penpot | `http://localhost:9001` | `https://penpot.home.arpa` |
| Dockhand | `http://localhost:2000` | `https://container.home.arpa` |
| Mailpit | `http://localhost:8025` | — |

When using direct HTTP, set the corresponding `publicUri` back to its HTTP URL.
App authentication expects the configured origin. Databases have no host ports.
Dockhand uses the Docker Desktop daemon socket to manage containers in that VM.

The Compose project is named `cirius`. Runtime secrets are generated once in
`$XDG_DATA_HOME/cirius-containers/runtime.env` (normally
`~/.local/share/cirius-containers/runtime.env`), with private permissions.
`container.dataDir`, `dockerCommand` and `dockerContext` can override the defaults;
the latter two default to Docker Desktop's bundled CLI and `desktop-linux`.
Run `docker context ls` if your Desktop context has a different name.

The rendered Compose file is `~/.config/cirius-containers/compose.yaml`. It contains
runtime variable references, not secret values. `cnix-containers config` validates
quietly so it does not print interpolated secrets.

Doop, both databases, Penpot assets and Dockhand data use named volumes in Docker
Desktop. Dockhand's automatically generated encryption key stays in its data
volume. `down` preserves these volumes and the env file. Back up the volumes and
env file together; do not run `down -v`, reset Docker Desktop data, or delete the
env file to upgrade an existing installation. This module never copies Linux
database directories to the Mac.

## Local Caddy HTTPS

The example runs native Caddy under launchd, binds its proxies to loopback and
keeps its CA/state in `/var/lib/cirius-caddy`. It does not install DNS services.
Add this one line to `/etc/hosts` on the Mac if your DNS does not already resolve
these names locally; preserve the existing entries:

```text
127.0.0.1 doop.home.arpa penpot.home.arpa container.home.arpa
```

After activation and the first request, trust this installation's Caddy CA once
in the macOS System Keychain:

```sh
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain \
  /var/lib/cirius-caddy/data/caddy/pki/authorities/local/root.crt
```

Caddy does not automatically modify the Keychain. This CA is separate from the
Linux Caddy CA. Logs are in `/var/log/cirius-caddy.log`; configuration is available
at `/etc/cirius/Caddyfile`. A temporary 502 means the container app is not ready
yet; start Docker Desktop and check `cnix-containers ps` and `logs`.

## Minimal verification

On Linux, evaluate a consumer's Darwin `system.drvPath` and its existing Linux
`config.system.build.toplevel.drvPath`. On the Mac, build the Darwin system,
then activate when ready. Start the stack, check Doop `/healthz`, create a Penpot
design and export it, test its MCP connection, and confirm Dockhand lists the
containers. Restart the stack once and confirm data persists.

Registry manifests were checked for all ten selected image tags: each includes
`linux/arm64`, including all five Penpot 2.18.6 components and the normal Dockhand
tag. Manifest availability is not a runtime test. Doop's ARM build,
Docker Desktop ports/volumes, launchd and Keychain trust need a real Mac smoke
check. No Linux-to-Darwin runtime equivalence is claimed by evaluation alone.
