---
title: Extending
sidebar_position: 5
description: Add a new subflake, module, or option to the facade.
---

# Extending

The facade is meant to grow deliberately — a new module should earn its place by
capturing a setting worth keeping. When it does, the conventions in
[Design](./design.md) make it a small, local change.

## 1. Create the subflake

Create `flakes/<name>/flake.nix` following the existing pattern: set a unique
`namespace`, wire inputs (with `inputs.nixpkgs.follows = "nixpkgs"`), and call
`core.mkFlake`.

## 2. Drop in modules

Modules live under `flakes/<name>/modules/<class>/<module>/default.nix`, where
`<class>` is one of `home`, `nixos`, or `darwin`. A
`modules/<class>/default/default.nix` aggregate is picked up automatically and
imports every sibling module — useful for one-line opt-in.

## 3. Namespace the options

Namespace options and config under `options.${namespace}.<module>` so they don't
collide with upstream options, and guard them behind an `enable` flag. Use the
`cirius-lib` builders so the option's description and default are declared in one
place:

```nix
{ config, lib, namespace, inputs, ... }:
let
  inherit (lib) mkIf mkOption types;
  cnix-lib = inputs.cirius-lib.lib;
in
{
  options.${namespace}.example.enable = cnix-lib.mkBoolOpt {
    description = "Enable the example module.";
  };

  config = mkIf config.${namespace}.example.enable {
    # set ordinary upstream options here
  };
}
```

Consumers can then enable the module with `cnix-<short>.example.enable = true;`.

## 4. Document it

Each subflake has a page under `docs/flakes/` in `apps/website` describing its
modules and listing every option with its type, default, and effect. When you add
or change an option, update that page in the same commit.
