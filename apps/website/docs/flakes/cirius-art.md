---
title: cirius-art
sidebar_position: 8
description: Drawing, 3D, and generative art tooling, including the flake's own pen.dev and ComfyUI packages.
---

# cirius-art

Creative tooling, including the flake's own packaged builds of pen.dev and
ComfyUI desktop. Nothing here is subtle: it is a curated package set for drawing,
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
and FreeCAD alongside the flake's own `comfy-desktop`, `pen-cli`, and
`pen-desktop` packages.

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
| `pen-cli` | Wrapper around the prebuilt `@pen.dev/cli` npm tarball, providing `pen` and `pencil`. |
| `pen-desktop` | AppImage-wrapped pen.dev desktop app with the bundled MCP server. |

There are no overlays or library helpers in this flake.
