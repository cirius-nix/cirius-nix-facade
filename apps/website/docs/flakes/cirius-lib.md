---
title: cirius-lib
sidebar_position: 11
description: The shared option builders and assertion helper every subflake uses.
---

# cirius-lib

The smallest flake and the one everything else depends on: no modules, no
packages, just the helpers that make a hundred option declarations uniform. It
exists so a module author writes a description and a default, and never repeats
the shape of `lib.mkOption`.

| | |
| --- | --- |
| Namespace | `cnix-lib` |
| Module classes | — *(library only)* |
| External inputs | — |
| Exported helpers | 11 |

## Usage

```nix
{
  inputs.cirius-lib = {
    url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-lib";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Consumers reach the helpers through `inputs.cirius-lib.lib`; inside a flake that
already depends on it they read `inputs.cirius-lib.lib.mkBoolOpt` directly, as
every module here does.

## Option builders

All builders except `failWhen` take one attribute set and return the result of
`lib.mkOption`. None of them are module-system aware — they are pure functions,
which is why they can be used while building submodule types.

| Helper | Type produced | Notes |
| --- | --- | --- |
| `mkPrimOpt` | *(the type you pass)* | The base builder everything else wraps: `mkPrimOpt primitiveType { … }`. |
| `mkBoolOpt` | `bool` | |
| `mkStrOpt` | `str` | |
| `mkIntOpt` | `int` | |
| `mkFloatOpt` | `float` | |
| `mkPathOpt` | `path` | |
| `mkPackageOpt` | `package` | |
| `mkEnumOpt` | `enum values` | Takes `values` (a list); defaults to `[ ]`. |
| `mkListOpt` | `listOf ofType` | Takes `ofType`; defaults to `anything`. |
| `mkAttrsOpt` | `attrsOf ofType` | Takes `ofType`; defaults to `anything`. |

### Arguments

Every `mk*Opt` builder accepts the same attribute set, with all keys optional:

| Argument | Type | Default | Effect |
| --- | --- | --- | --- |
| `description` | `str` | `""` | Rendered in `nixos-option`, search, and docs. Falls back to the literal string `"Value to be set"` when left empty. |
| `default` | *any* | `null` | The option's default. Emitted only when `default != null` **or** `nullable = true` — otherwise the option has no `default` attribute at all. |
| `nullable` | `bool` | `false` | Wraps the type in `nullOr`, which also makes `null` a valid default. |
| `readOnly` | `bool` | `false` | Marks the option read-only, for values a module computes rather than accepts. |
| *anything else* | — | — | Accepted and ignored, so a shared attrset can be spread into a builder. |

The two behaviours worth remembering are the description fallback and the
`default` omission: an option built as `mkStrOpt { description = "…"; }` has no
default, so NixOS treats it as unset until a consumer provides it. Several
modules in the facade rely on that, and their pages mark such options with `—`.

## Assertions

| Helper | Signature | Returns |
| --- | --- | --- |
| `failWhen` | `{ condition, message }` | An assertion attrset: `{ assertion = condition == false; message; }` |

`failWhen` reads best as "fail when this is true". A module pairs it with a
message that says what to fix, so an inconsistent configuration fails at
evaluation with an explanation instead of producing a broken system.

## Example

```nix
let
  cnix-lib = inputs.cirius-lib.lib;
in
{
  options.${namespace}.example = {
    enable = cnix-lib.mkBoolOpt {
      description = "Enable the example module.";
      default = false;
    };

    registry = cnix-lib.mkStrOpt {
      description = "Registry to pull images from.";
      default = "docker.io";
    };

    credentials = cnix-lib.mkAttrsOpt {
      ofType = lib.types.str;
      default = { };
      description = "Credentials to pass through to the service.";
    };
  };

  config.assertions = [
    (cnix-lib.failWhen {
      condition = config.${namespace}.example.enable && config.${namespace}.example.registry == "";
      message = "example.registry must be set when example.enable is true.";
    })
  ];
}
```
