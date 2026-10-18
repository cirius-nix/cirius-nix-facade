---
title: cirius-gaming
sidebar_position: 6
description: Gaming platforms, emulation, GameMode and Gamescope, and a CUDA-enabled Sunshine streaming host.
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
| External inputs | `eden` |
| Options | 10 |

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

### `nixos/default` — platforms and runtime

Aggregates the emulator and stream modules and carries the shared options.

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
