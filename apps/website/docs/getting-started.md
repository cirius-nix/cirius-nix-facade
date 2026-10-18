---
title: Getting started
sidebar_position: 2
description: Consume a subflake, enable a module, and override anything it sets.
---

# Getting started

## 1. Add the subflake as an input

Subflakes are referenced directly by directory with the `?dir=` query parameter.
To pull in the dev flake, add it as an input:

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

## 2. Import the aggregate module

Each subflake's `modules/<class>/default` aggregate imports every module in that
class, which is what makes the whole option surface available with a single
import:

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-dev.homeModules.default ];
}
```

At this point nothing has changed about your system: every module is still off.

## 3. Enable what you need

Each concern is one line. Nothing else in the module applies until you set it:

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-dev.homeModules.default ];

  cnix-dev.git.enable = true;
  cnix-dev.shell.enable = true;
  cnix-dev.term.enable = true;
}
```

For NixOS-level modules, the same pattern applies to the `nixosModules`
aggregate — see the per-flake pages under [Flakes](./flakes/index.md) for which
class a module belongs to and what its `enable` option is called.

## Overriding what a module sets

Modules configure ordinary upstream options, so you are never locked in. To
change a value a module picks, override it at your own level:

```nix
{
  cnix-dev.git.enable = true;

  # the module's own value, replaced
  programs.git.userEmail = lib.mkForce "me@example.com";
}
```

Anything the facade does not cover is still plain home-manager and NixOS
configuration — add it next to the module rather than working around it. That is
the intended shape: modules handle the setup, you keep writing normal Nix.

## Sharing helpers between your config and the flakes

`cirius-lib` exposes the same option builders the subflakes use, if you write
modules of your own:

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

Library functions are then available as `inputs.cirius-lib.lib`. See
[cirius-lib](./flakes/cirius-lib.md).
