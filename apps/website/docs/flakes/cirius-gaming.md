---
title: cirius-gaming
sidebar_position: 6
description: Gaming platforms, emulation, Sunshine capture and opt-in Wolf virtual streaming sessions.
---

# cirius-gaming

A gaming stack for a machine that plays and, optionally, streams. Platforms and
emulators are selected from lists rather than individual flags, and the streaming
module carries the encoder tuning that is annoying to rediscover — KMS capture,
NVENC, and the uinput/input group membership Sunshine needs.

| | |
| --- | --- |
| Namespace | `cnix-gaming` |
| Module classes | `nixos` |
| External inputs | `eden`, `wolf-nvidia-vol` |
| Options | 19 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-gaming.nixosModules.default ];

  cnix-gaming.usePlatforms = [ "steam" "lutris" ];
  cnix-gaming.emulator.useClients = [ "retroarch" "eden" ];
  cnix-gaming.stream.enable = true;
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | nixos | `cnix-gaming.useRecommendedPackages` | Toolchain, platforms, GameMode, Gamescope |
| `emulator` | nixos | `cnix-gaming.emulator.useClients` | RetroArch, Eden |
| `stream` | nixos | `cnix-gaming.stream.enable` | Sunshine host |
| `wolf` | nixos | `cnix-gaming.wolf.enable` | Separate virtual streaming sessions |

### `nixos/default` — platforms and runtime

Aggregates the emulator, stream and Wolf modules and carries the shared options.

`useRecommendedPackages` installs the supporting toolchain — ProtonUp-Qt,
ProtonPlus, Wine, MangoHud, Protontricks, and shadPS4 with its Qt launcher —
enables 32-bit graphics (which many games still require), and turns on GameMode.
Platforms are opt-in through `usePlatforms`: `"steam"` enables Steam with
Remote Play and dedicated-server firewall openings, `"lutris"` installs Lutris.

`gamescope.enable` turns on the compositor with `capSysNice` for scheduling
priority; `gamescope.hdr` additionally enables WSI support for HDR output.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-gaming.useRecommendedPackages` | `bool` | `true` | Use recommended packages for gaming | Installs the gaming toolchain, enables 32-bit graphics, and enables GameMode. |
| `cnix-gaming.usePlatforms` | `listOf str` | `[ ]` | Enable gaming platforms. | Each entry (`"steam"`, `"lutris"`) enables that platform. |
| `cnix-gaming.gamescope.enable` | `bool` | `false` | Enable gamescope | Enables Gamescope with `capSysNice`, and the Steam Gamescope session. |
| `cnix-gaming.gamescope.hdr` | `bool` | `false` | Enable HDR support in gamescope | Enables WSI so HDR can be used. |

### `nixos/emulator` — emulation clients

Client selection by list. RetroArch is installed directly; Eden installs
`vulkan-tools` and enables `programs.eden` from the flake's `eden` input.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-gaming.emulator.useClients` | `listOf str` | `[ ]` | Enable emulator clients. | Each entry (`"retroarch"`, `"eden"`) installs or enables that client. |

### `nixos/stream` — Sunshine streaming host

**Enable:** `cnix-gaming.stream.enable`

Runs Sunshine with CUDA support and a settings block tuned for low-latency
capture over KMS (`capture = "kms"`, `encoder = "nvenc"`, `fec_percentage = 20`,
`qp = 28`, unpinned bitrate). Users listed in `settings.users` are added to the
`uinput` and `input` groups, which is what lets remote clients inject input.
`csrf_allowed_origins` is built from the `origins` list, so the allowed origins
stay declarative rather than being edited in Sunshine's UI.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-gaming.stream.enable` | `bool` | `false` | Enable streaming services. | Enables the CUDA-enabled Sunshine host. |
| `cnix-gaming.stream.settings.port` | `int` | `47989` | Port for the stream service. | Sunshine's listening port. |
| `cnix-gaming.stream.settings.displayID` | `str` | `"stream"` | Display ID for the stream output. | Sets the output name Sunshine captures. |
| `cnix-gaming.stream.settings.users` | `listOf str` | `[ ]` | List of users to add to the uinput and input groups. | Grants input-injection permissions to those users. |
| `cnix-gaming.stream.settings.origins` | `listOf str` | `[ ]` | List of origins to allow for the stream service. | Joined into `csrf_allowed_origins`. |

## Packages and overlays

The flake exports an `eden` overlay (from the `eden` input) and no packages of
its own.

### `nixos/wolf`: virtual streaming sessions

**Enable:** `cnix-gaming.wolf.enable`

[Wolf](https://games-on-whales.github.io/wolf/stable/) creates virtual displays,
audio and input for streamed applications. It does not capture the existing KDE
session, reuse its audio sockets, or alter the Sunshine module. Import the
`wolf` module directly for only this service, or use the existing `default`
aggregate. Nothing starts until the consuming host explicitly enables it and
activates that configuration.

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-gaming.nixosModules.wolf ];
  cnix-gaming.wolf = {
    enable = true;
    nvidia.enable = true; # omit for Intel/AMD
    renderNode = "/dev/dri/renderD128"; # verify the GPU, do not guess
    # openFirewall = true; # only on an appropriately restricted trusted network
  };
}
```

| Option | Default | Purpose |
| --- | --- | --- |
| `enable` | `false` | Opt into the Wolf service. |
| `image` | `stable@sha256:47ce7a0b…` | Verified upstream image pinned by its full manifest digest in the module. |
| `port` | `48989` | HTTP base port, separate from Sunshine's default range. |
| `openFirewall` | `false` | Open the six Wolf ports on all interfaces. |
| `dataDir` | `/var/lib/wolf` | Persistent configuration, pairing and application state. |
| `renderNode` | `/dev/dri/renderD128` | GPU used by the virtual compositor. |
| `nvidia.enable` | `false` | Mount matching NVIDIA userspace drivers for Wolf and child containers. |
| `nvidia.driverVolume` | Nix-built driver bundle | Override the container-compatible `/usr/nvidia` tree. |
| `nvidia.devices` | Upstream single-GPU device list | Override NVIDIA device nodes for this host. |

#### Container engine and NVIDIA

The module follows `virtualisation.oci-containers.backend`, normally Podman on
NixOS and in `cnix-virt.container`. It enables the selected engine through the
upstream OCI module and mounts that engine's rootful API socket, without
replacing the backend, the Docker compatibility alias, or existing containers.
The service is `podman-wolf.service` or `docker-wolf.service`.

NVIDIA needs an already configured host NVIDIA driver with modesetting enabled.
The module does not replace that driver or turn on a display manager. It loads
`nvidia_uvm` in addition to `uinput` and `uhid`. Verify the GPU and available
nodes before activation:

```sh
ls -l /sys/class/drm/renderD*/device/driver
ls -l /dev/nvidia* /dev/nvidia-caps/* /dev/uinput /dev/uhid
cat /sys/module/nvidia_drm/parameters/modeset
```

The default bundle uses the locked
[`wolf-nvidia-vol` helper](https://github.com/altano/flakes/tree/main/wolf-nvidia-vol)
to build the userspace files from `hardware.nvidia.package` and include
`cuda_nvrtc` for GStreamer's CUDA conversion. Its build requires an
**x86_64-linux, KVM-capable builder**. This uses the manual-driver layout
recommended by [Wolf upstream](https://games-on-whales.github.io/wolf/stable/user/quickstart.html),
with a Nix store path instead of a mutable named volume. Wolf passes the same
path to child containers. Merely enabling NVIDIA CDI for the parent does not
establish that its child containers have the right libraries.

After changing the host driver, reboot into the matching kernel driver before
starting the new Wolf generation. A new userspace bundle with an old loaded
kernel driver can fail. If a listed device does not exist, check the loaded
driver and adjust `nvidia.devices`; do not make all of `/dev` world-writable.

#### Ports, pairing and persistent data

With the default base port, Wolf uses TCP **48984, 48989, 49010** and UDP
**48999, 49100, 49200**. The module rejects overlapping Sunshine ports rather
than disabling or moving Sunshine. It does not check other applications for
port conflicts. Host networking still listens on the host even when
`openFirewall = false`; existing firewall/trusted-interface policy determines
reachability. Prefer interface-specific firewall rules or an existing trusted
VPN rather than opening these ports to the internet. This module does not
configure routing, NAT, UPnP, a reverse proxy, or VPN access.

Add the server manually in a Moonlight client that supports a custom HTTP port,
using `HOST_IP:48989`. Pairing is completed through the one-time URL in Wolf's
service log, using the PIN Moonlight displays. Custom ports are not supported by
every client, so verify this on the target devices. The default upstream apps
include Wolf UI for managing profiles/applications; the first launch can take
longer while images are downloaded.

```sh
journalctl -u podman-wolf -f # use docker-wolf with the Docker backend
```

`dataDir` is mounted writable at `/etc/wolf`. Wolf owns its mutable TOML,
certificates, paired clients and profile/application directories there. Do not
symlink that configuration into the read-only Nix store or commit pairing keys.
Back up this directory, including `cfg/` and `profile_data/`; it is retained when
the module is disabled. Profiles deliberately shared between clients can share
app data. A separate session is not automatically a separate user profile.

`/run/wolf` holds the local management socket and `/run/wolf-runtime` holds the
virtual compositor/audio sockets. Both host directories are root-only. The
parent mounts the runtime directory at the same path, and Wolf bind-mounts the
individual sockets into child containers. They are temporary and recreated at
boot. No local desktop Wayland, X11, PulseAudio or PipeWire socket is mounted.

The pinned image was published on 2026-11-01 from upstream commit
[`db709cfd`](https://github.com/games-on-whales/wolf/commit/db709cfd3f0f49dfd7d00495940119309692b535)
and includes embedded PulseAudio. The documented monthly tags were not available
in the registry when this module was added, so it pins the verified stable
manifest instead. Older/custom images relying on the non-root
`WolfPulseAudio` fallback sidecar are not compatible with these root-only runtime
directories; verify compatibility before overriding `image`.

#### Security and device acceptance

Wolf manages other containers through the rootful Docker-compatible API.
**That socket grants effective host-root control.** The parent also sees host
`/dev`, udev state, host networking and IPC, as required by upstream. Do not run
untrusted app images or treat this as a sandbox for hostile users. Pair only
trusted clients. The parent image is digest-pinned, but child-app images and
mutable app/profile configuration are not locked by Nix. Pin app images too
when reproducibility is required.

Wolf virtual input devices are assigned to a separate seat, excluded from
libinput and made root-only with `uaccess` removed. The rules cover virtual
pads and their touchpad, motion-sensor and hidraw nodes. Root-only permissions
also exclude desktop users who already belong to `input` for Sunshine. Physical
host devices and user group membership are unchanged. These rules reduce input
leakage; they do not prove isolation on every kernel, controller or application.

After the user activates the configuration, check with the actual Moonlight
devices: pair, launch a game, reconnect, try simultaneous sessions, check video
encoding/audio, and confirm controller/touchpad input does not move or type into
the local KDE session. Keep a local recovery session available. Stop Wolf if
input reaches the host desktop and inspect the affected device's udev
properties/ACLs before continuing. Hardware streaming and host-input isolation
have not been verified by this repository change; no automated tests were added.
