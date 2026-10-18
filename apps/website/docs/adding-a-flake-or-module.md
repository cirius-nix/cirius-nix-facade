---
title: Adding a flake or module
sidebar_position: 4
description: The three steps for extending the facade with a new subflake or module.
---

# Adding a flake or module

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
collide with upstream options, and guard them behind an `enable` flag:

```nix
{ config, lib, namespace, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.${namespace}.example.enable = mkEnableOption "the example module";

  config = mkIf config.${namespace}.example.enable {
    # ...
  };
}
```

Consumers can then enable the module with `cnix-<short>.example.enable = true;`.
