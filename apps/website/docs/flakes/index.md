---
title: Flakes
description: Every subflake with its namespace, modules, and a full option reference.
---

# Flakes

Eleven subflakes, one concern each. Every page below follows the same shape: what
the flake is for, the modules it ships with what they actually configure, and a
complete option reference for the options that flake declares.

Read a page when you want to know what a concern covers, what turning it on will
do, and which knobs exist.

## Overview

| Flake | Namespace | Classes | Modules | Options | Covers |
| --- | --- | --- | --- | --- | --- |
| [cirius-utils](./cirius-utils.md) | `cnix-utils` | home, nixos | 7 | 37 | Base layer: flatpak, desktop behaviour, shortcuts, power, web apps, KDE Connect/Syncthing |
| [cirius-security](./cirius-security.md) | `cnix-sec` | home, nixos | 9 | See reference | SOPS, SSH, tunnels, LUKS, firewall, Fail2ban |
| [cirius-dev](./cirius-dev.md) | `cnix-dev` | home, nixos | 19 | 40 | Editors, shell, terminal, git, AI clients, nine language toolchains, self-hosted CI runner |
| [cirius-visual](./cirius-visual.md) | `cnix-visual` | home, nixos | 9 | 27 | Stylix theming, fonts, KDE Plasma, GNOME, panels, theme switcher |
| [cirius-networking](./cirius-networking.md) | `cnix-net` | nixos | 2 | 10 | AdGuard Home DNS filtering, SSH, Caddy, host table, Tailscale |
| [cirius-gaming](./cirius-gaming.md) | `cnix-gaming` | nixos | 3 | 10 | Steam/Lutris, emulators, GameMode, Gamescope, Sunshine streaming |
| [cirius-virt](./cirius-virt.md) | `cnix-virt` | home, nixos | 4 | 25 | Podman/OCI containers, libvirt base, EDID virtual displays |
| [cirius-art](./cirius-art.md) | `cnix-art` | home | 2 | 2 | Drawing, 3D, generative art, sprite tooling |
| [cirius-office](./cirius-office.md) | `cnix-office` | home | 1 | 2 | Tiered office/document tooling and Obsidian |
| [cirius-vn](./cirius-vn.md) | `cnix-vn` | nixos | 1 | 2 | Vietnamese input method and locale |
| [cirius-lib](./cirius-lib.md) | `cnix-lib` | — | 0 | 11 helpers | Option builders and assertions every other flake uses |

Option counts include submodule fields — a container instance or a theme entry
contributes several paths — and are taken from the current working tree.

## How to read these pages

- **Modules** are listed per flake with the option that enables them and what they
  configure upstream. "Configured" means real home-manager or NixOS options, so
  anything you see here can also be set — or overridden — directly.
- **Options** are given with path, type, default, description, and effect. A
  description of `—` means the source declares none; the effect column then
  explains what the option does.
- **Aliases** are called out, because an option that aliases an upstream option
  behaves exactly like it, and the upstream documentation applies.
- **`—` in the default column** means no default is declared at all. Options built
  through `cirius-lib` without a default behave as unset (NixOS reports them as
  required) rather than defaulting to `null`.

## Cross-flake dependencies

`cirius-lib` is the shared foundation: every flake that declares options uses its
builders, so descriptions, defaults, and nullable types behave the same way
everywhere. Beyond that, the flakes avoid depending on each other, which is what
keeps them independently lockable. Where a module builds on another, the pages say
so — for example `cirius-dev`'s toolchains only apply their editor wiring when
`cnix-dev.editor.nvim.enable` or `cnix-dev.editor.code.enable` is also set.
