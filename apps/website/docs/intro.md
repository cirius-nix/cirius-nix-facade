---
title: Introduction
sidebar_position: 1
description: What the Cirius Nix Facade is and why it has no root flake.nix.
---

# Introduction

The **Cirius Nix Facade** is a personal [Nix](https://nixos.org/) configuration
split into small, composable subflakes — one per concern. There is no root
`flake.nix`: this repository is a *facade* whose subflakes are consumed
individually by the actual host configurations (NixOS, nix-darwin, and
home-manager).

## Why a facade?

A single monolithic flake couples unrelated concerns: a change to your gaming
overlay re-evaluates your security modules, and every host pulls in every input.
Splitting the configuration into subflakes keeps each concern:

- **Independently consumable** — a host pulls in only the flakes it needs, using
  the `?dir=` query parameter to point at a subdirectory.
- **Independently lockable** — each subflake has its own `flake.lock`, so
  updating dev tooling cannot move your desktop stack.
- **Independently buildable** — a broken concern fails its own evaluation rather
  than every host that consumes the facade.

The cost is one extra layer of indirection, and sharing code between flakes needs
an explicit dependency — which is what `cirius-lib` exists for.

## How subflakes are built

Every subflake is built with
[snowfall-lib](https://github.com/snowfallorg/lib) `mkLib` / `mkFlake`. That means
packages, modules, overlays, and library functions are discovered from a
conventional directory layout and exposed under a per-flake namespace — `cnix-dev`
for the `cirius-dev` flake, for example.

Because discovery is convention-based, adding a module is usually a matter of
dropping a file in the right place. See
[Adding a flake or module](./adding-a-flake-or-module.md).

## Next steps

- [Getting started](./getting-started.md) — pull a subflake into your own config.
- [Layout](./layout.md) — the directory conventions every subflake follows.
- [Development](./development.md) — the dev shell for working on this repository.
