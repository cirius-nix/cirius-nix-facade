---
title: cirius-art
sidebar_position: 8
description: Drawing, 3D, and generative art tooling, including Pencil (pen.dev), OpenPencil and ComfyUI packages.
---

# cirius-art

Creative tooling, including the flake's packaged builds of Pencil (pen.dev),
OpenPencil and ComfyUI desktop. Nothing here is subtle: it is a curated package set for drawing,
3D, and generative image work, plus a separate flag for pixel-art tooling.

| | |
| --- | --- |
| Namespace | `cnix-art` |
| Module classes | `home` |
| External inputs | — |
| Options | 2 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-art.homeModules.default ];

  cnix-art.useRecommendedPackages = true;
  cnix-art.sprite.enable = true;
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | `cnix-art.useRecommendedPackages` | Drawing/3D/AI package set |
| `sprite` | home | `cnix-art.sprite.enable` | Pixel-art and tile tooling |

### `home/default` — art package set

Imports the `sprite` module, so both concerns are available from a single import.
With `useRecommendedPackages` it installs Inkscape, Blender, ImageMagick, Krita,
and FreeCAD alongside the flake's own `comfy-desktop`, `pencil-desktop`,
`openpencil-cli`, and `openpencil-desktop` packages on Linux. Darwin keeps its
existing ImageMagick-only subset.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-art.useRecommendedPackages` | `bool` | `false` | Whether to use recommended packages for art. | Installs the recommended toolchain plus the flake's own art packages. |

### `home/sprite` — sprite and tile tooling

**Enable:** `cnix-art.sprite.enable`

Installs Aseprite for pixel art and LDtk for level/tilemap design.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-art.sprite.enable` | `bool` | `false` | Enable sprite support. | Installs `aseprite` and `ldtk`. |

## Packages

Besides the modules, the flake exports packages under `pkgs.cnix-art`:

| Package | What it is |
| --- | --- |
| `comfy-desktop` | Packaged ComfyUI desktop app (Electron). |
| `pencil-desktop` | Official Pencil (pen.dev) Linux tarball, with the bundled Electron runtime and MCP server. |
| `openpencil-cli` | Wrapper around the prebuilt `@open-pencil/cli` npm tarball, providing `openpencil` plus the `openpencil-mcp` servers. |
| `openpencil-desktop` | AppImage-wrapped OpenPencil desktop app. |

### Pencil (pen.dev)

Pencil (now distributed as Pen at [pen.dev](https://www.pen.dev/downloads)) is a
separate proprietary product from [OpenPencil](https://openpencil.dev). Installing
`pencil-desktop` does not replace or rename the existing OpenPencil packages.

The package pins release **1.2.22** from the official
[highagency/pen-desktop-releases](https://github.com/highagency/pen-desktop-releases/releases/tag/v1.2.22)
repository. Both Linux tarballs have verified SHA-256 hashes and contain the same
application version: `x86_64-linux` uses `linux-x64`, and `aarch64-linux` uses
`linux-arm64`. The desktop executable, bundled agents and MCP helper are patched
for Nix library paths; the upstream application archive remains intact.

On Linux, `cnix-art.useRecommendedPackages = true` includes it. To select only
this app in a host that already uses the facade overlay:

```nix
{
  nixpkgs.config.allowUnfree = true;
  home.packages = [ pkgs.cnix-art.pencil-desktop ];
}
```

Launch `pencil-desktop`, or use the **Pencil (pen.dev)** menu entry. The package
also exposes `pencil-mcp-server`; configure the desktop's supported MCP
integration or pass the helper's required arguments when using it directly.
This package does not supply the separate npm `pen` CLI. It deliberately avoids
`pencil`, which is also the name of the unrelated Evolus application in Nixpkgs.

Pencil is [unfree](https://www.pen.dev/eula). Downloads use versioned release URLs,
not the rolling download endpoint or expiring signed redirects. Only packaging
code and hashes belong in Git: do not publish the tarballs or built package to a
public binary cache. The package prefers local builds and disables substitution;
this does not prevent an explicit upload, so do not upload it. Keep updates under
Nix rather than the application's updater, since the Nix store is read-only.

To update, choose a versioned upstream release, update `version` and both hashes
in `packages/pencil-desktop/default.nix`, and verify the tarballs' embedded version
and ELF architecture. Build and smoke-check on x86_64 Linux. ARM64 source checks
and derivation evaluation do not substitute for running it on an ARM64 Linux host.

There are no custom overlays or library helpers in this flake; Snowfall exports
the packages through its generated overlay.
