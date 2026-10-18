---
title: Design
sidebar_position: 3
description: Why the facade is split into subflakes, and the conventions and option builders behind every module.
---

# Design

## The problem

Managing Linux machines as infrastructure-as-code tends to drift in one
direction: more code. Every host grows its own shell setup, its own git config,
its own editor wiring, and every one of those is a module you now have to
maintain. Most of that code is not the valuable part — it is the setup you need
before any valuable work can happen.

The facade takes the position that a personal Linux configuration should be
**small and boring**: capture the settings that are genuinely worth keeping,
inherit everything else.

## Principles

### Simple by default

Every module is guarded by an `enable` flag defaulting to `false`, and every
option carries a working default. You can turn on a concern and get a sensible
system without reading a single option table — the tables exist for when you
want to change something, not before.

### Powerful when needed

Nothing is wrapped or re-exported. Modules set ordinary upstream options
(`services.flatpak.enable`, `programs.ssh.settings`, `programs.nixvim.*`), and
options are ordinary NixOS options. That means the module is a starting point you
can override with `lib.mkForce`, extend with extra packages and settings, or
bypass entirely by configuring the upstream option yourself.

### One concern per subflake

A single monolithic flake couples unrelated concerns: a change to a gaming
overlay re-evaluates your security modules, and every host pulls in every input.
Splitting the configuration per concern keeps each one independently consumable,
independently lockable, and independently buildable:

- **Consumable** — a host pulls in only the flakes it needs, via `?dir=`.
- **Lockable** — each subflake has its own `flake.lock`, so updating your dev
  toolchain cannot move your desktop stack.
- **Buildable** — a broken concern fails its own evaluation rather than every
  host that consumes the facade.

The cost is one layer of indirection, and sharing code between flakes needs an
explicit dependency — which is what `cirius-lib` is for.

### No root flake

There is deliberately no root `flake.nix`. This repository is a *facade*: hosts
consume subflakes individually, so there is no single evaluation that every
machine depends on, and no lockfile that unifies unrelated inputs.

## Conventions

### Repository

```
.
├── flakes/                    # one subflake per concern
│   ├── cirius-lib/            # shared library helpers (no modules)
│   ├── cirius-utils/
│   ├── cirius-security/
│   ├── cirius-dev/
│   ├── cirius-visual/
│   ├── cirius-networking/
│   ├── cirius-gaming/
│   ├── cirius-art/
│   ├── cirius-office/
│   ├── cirius-virt/
│   └── cirius-vn/
├── apps/
│   └── website/               # this site
├── devenv.nix                 # dev shell for working on this repo
├── devenv.yaml
└── Taskfile.yml
```

### Subflake

Each subflake follows the same [snowfall-lib](https://github.com/snowfallorg/lib)
conventions:

```
flakes/<name>/
├── flake.nix
├── modules/
│   ├── home/<module>/default.nix      # home-manager modules
│   ├── nixos/<module>/default.nix     # NixOS modules
│   ├── darwin/<module>/default.nix    # nix-darwin modules
│   └── <class>/default/default.nix    # aggregate: imports every sibling module
├── packages/<pkg>/default.nix         # packages exported by the flake
├── overlays/<overlay>/default.nix     # nixpkgs overlays
└── lib/default.nix                    # flake-local library helpers
```

Two conventions matter when you consume a subflake:

- **The aggregate module.** `modules/<class>/default` is discovered
  automatically and imports every sibling module. Importing it is enough to make
  a flake's whole option surface available, so consumers never need to track
  individual module paths. See [Flakes](./flakes/index.md) for what each
  aggregate imports.
- **Namespacing.** Options live under the flake's namespace (`cnix-dev`,
  `cnix-sec`, …) so they never collide with upstream options, and every module is
  guarded by an `enable` flag.

Some modules go one step further and alias their enable flag onto the upstream
option via `lib.mkAliasOptionModule` — for example
`cnix-utils.package-manager.flatpak.enable` is the same option as
`services.flatpak.enable`. Aliases are noted per module in the
[flake reference](./flakes/index.md).

### Shared option builders

`cirius-lib` exists so every subflake describes its options the same way. Instead
of repeating `lib.mkOption { type = ...; }` blocks, modules use small builders
that take a description and an optional default:

```nix
cnix-lib.mkBoolOpt {
  description = "Enable the thing.";
  default = false;
}
```

The builders (`mkBoolOpt`, `mkStrOpt`, `mkIntOpt`, `mkListOpt`, `mkAttrsOpt`,
`mkPackageOpt`, `mkPathOpt`, `mkEnumOpt`, and the `mkPrimOpt` base) all forward to
`lib.mkOption`, add support for a `nullable` variant of the type, and fall back to
a generic description when none is given. `failWhen` is a companion helper for
module assertions. The full list is documented in
[cirius-lib](./flakes/cirius-lib.md).

## Extending the facade

Adding a module to an existing subflake is a matter of dropping a file in the
right place and namespacing its options — see
[Extending](./extending.md).
