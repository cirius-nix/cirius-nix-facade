---
title: cirius-vn
sidebar_position: 10
description: Vietnamese input method and locale configuration in a single NixOS module.
---

# cirius-vn

Vietnamese input and locale, for the machines that need it. One flag turns on the
fcitx5-lotus input method for the listed users, sets the time zone, and applies
`vi_VN` locale settings for formatting — while keeping the system language
English.

| | |
| --- | --- |
| Namespace | `cnix-vn` |
| Module classes | `nixos` |
| External inputs | `fcitx5-lotus`, `cirius-lib` |
| Options | 2 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-vn.nixosModules.default ];

  cnix-vn.enable = true;
  cnix-vn.inputMethod.users = [ "me" ];
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | nixos | `cnix-vn.enable` | Input method, time zone, locale |

### `nixos/default` — input method and locale

**Enable:** `cnix-vn.enable`

Sets `i18n.inputMethod` to fcitx5 and enables `services.fcitx5-lotus` for the
users in `inputMethod.users` (fcitx5-lotus needs to know which users to run for).
It sets the time zone to `Asia/Ho_Chi_Minh`, and applies Vietnamese settings to
the address, identification, measurement, monetary, name, numeric, paper,
telephone, and time categories via `LC_*`, leaving `LANG` at `en_US.UTF-8`.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-vn.enable` | `bool` | `false` | Enable Cirius Nix Vietnam supports | Enables fcitx5-lotus, the Vietnamese locale settings, and the time zone. |
| `cnix-vn.inputMethod.users` | `listOf str` | `[ ]` | List of users to enable fcitx5-lotus input method | Users the input method runs for. |

## Notes

- The single module in this flake is also its aggregate — there are no sibling
  modules to import.
- Locale values are set through `extraLocaleSettings`, so the display language
  stays as whatever the host configures.
