---
title: Introduction
sidebar_position: 1
description: A small, opinionated NixOS facade that replaces piles of infra-as-code with the settings that actually matter.
---

# Introduction

Configuring Linux as infrastructure-as-code usually starts simple and ends up
complicated: a few machines, a handful of concerns, and a growing pile of
hand-written modules to hold it together. **Cirius Nix Facade** is the opposite
approach — it manages the core, valuable settings that keep Linux running well,
and leaves the rest to NixOS and home-manager defaults.

It is a personal [Nix](https://nixos.org/) configuration split into small,
composable subflakes — one per concern — that a host configuration picks up. The
goal is not to configure everything. The goal is to configure the right things,
once.

## What it gives you

- **Less setup per machine.** A new host enables a handful of `cnix-*` options
  instead of re-deriving the same shell, git, editor, and security setup from
  scratch.
- **Less infra-as-code to own.** Around 160 namespaced option paths across eleven
  subflakes — a surface small enough to read in one sitting, and to actually keep
  working.
- **NixOS defaults underneath.** Modules configure the upstream home-manager and
  NixOS options you would otherwise have written by hand, so anything not covered
  is still normal NixOS you can add yourself.
- **A foundation, not a framework.** Each subflake is a plain flake built on
  [snowfall-lib](https://github.com/snowfallorg/lib) conventions, with no custom
  evaluator and no hidden layer between you and nixpkgs.

## Simple by default, powerful when needed

Every module is off until you turn it on, and every option has a working default.
Enabling a concern is one line:

```nix
cnix-dev.git.enable = true;
```

When the default is not what you want, the module gets out of the way. Options
are ordinary NixOS options, so they compose with everything else you already
write: override a value with `lib.mkForce`, add extra packages, or drop to plain
`programs.*` configuration alongside the module. See
[Design](./design.md) for how that layering works.

## Where to start

- [Getting started](./getting-started.md) — consume a subflake and enable your
  first module.
- [Design](./design.md) — the principles behind the facade and its conventions.
- [Flakes](./flakes/index.md) — every subflake, its modules, and a full option
  reference for each.
- [Development](./development.md) — the dev shell for working on this repository.
