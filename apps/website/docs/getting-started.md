---
title: Getting started
sidebar_position: 2
description: Consume a Cirius Nix subflake from your own NixOS, nix-darwin, or home-manager configuration.
---

# Getting started

Subflakes are referenced directly by their directory with the `?dir=` query
parameter. To pull in the dev flake, add it as an input:

```nix
{
  inputs.cirius-dev = {
    url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Always set `inputs.nixpkgs.follows = "nixpkgs"` so the subflake shares your
host's nixpkgs instead of pinning a second copy.

## Enabling modules

Modules namespace their options under the flake's namespace and guard them behind
an `enable` flag, so they never collide with upstream options. Enabling one is a
single line:

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-dev.homeModules.default ];

  cnix-dev.git.enable = true;
}
```

## Sharing code between flakes

The flakes share helpers through `cirius-lib`, which exposes option builders such
as `mkStrOpt`, `mkBoolOpt`, and `mkPackageOpt`, plus `failWhen` assertion helpers.
Consume it the same way as any other subflake:

```nix
{ inputs, ... }:
{
  inputs.cirius-dev.url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-dev";
  inputs.cirius-lib = {
    url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-lib";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Library functions are then available as `inputs.cirius-lib.lib`.
