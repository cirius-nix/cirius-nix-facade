---
title: cirius-security
sidebar_position: 2
description: SOPS secret management, SSH agent and config, autossh port-forwarding profiles, and a LUKS-backed secure store.
---

# cirius-security

Secrets and remote access, wired the way a single-user machine actually uses
them: secrets decrypted by an age key, one SSH agent shared by everything that
needs it, and long-lived tunnels declared as profiles instead of being started by
hand. The LUKS module covers the one case where a second encrypted volume is
worth the trouble.

| | |
| --- | --- |
| Namespace | `cnix-sec` |
| Module classes | `home`, `nixos` |
| External inputs | `sops-nix` |
| Options | 21 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-security.homeModules.default ];

  cnix-sec.ssh.enable = true;
  cnix-sec.secret-mgt = {
    enable = true;
    settings.ageKeyFile = "/home/me/.config/sops/age/keys.txt";
    settings.defaultSecretFile = ./secrets.yaml;
  };
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | *(always applies)* | sops/age packages, SSH agent and config |
| `secret-mgt` | home | `cnix-sec.secret-mgt.enable` | sops age key, format, default file |
| `ssh-port-mgt` | home | `cnix-sec.ssh-port-mgt.enable` | autossh tunnel profiles |
| `default` | nixos | *(always applies)* | sops/age packages, sops module |
| `secret-mgt` | nixos | `cnix-sec.secret-mgt.enable` | sops activation, tmpfs, age key |
| `secure-store` | nixos | `cnix-sec.secure-store.enable` | LUKS device and mount |

### `home/default` — SSH agent and config

Not gated by its own enable flag: it always provides the sops and age packages,
and the SSH behaviour is switched with `cnix-sec.ssh.enable`.

When SSH is enabled it starts the SSH agent with a long default identity lifetime
(8 hours, set as `mkDefault` so you can override it), enables `programs.ssh` with
the default config disabled — so only what you declare applies — and adds
`AddKeysToAgent = "yes"` for all hosts. Extra config files are pulled in as
`Include` lines, which is how an existing `~/.ssh/config` keeps working.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.ssh.enable` | `bool` | `false` | Enable SSH configuration. | Starts the SSH agent, enables `programs.ssh`, applies the Include lines. |
| `cnix-sec.ssh.additionalConfigPaths` | `listOf str` | `[ ]` | Additional SSH configuration files to include. | One `Include <path>` line per entry in `programs.ssh.extraConfig`. |

### `home/secret-mgt` — SOPS secrets in the home profile

**Enable:** `cnix-sec.secret-mgt.enable`

Points sops at your age key (`mkForce`, because a wrong key silently breaks
decryption), defaults the secret format to YAML and the secret file to
`settings.defaultSecretFile` (both `mkDefault`, so a specific secret can override
them). The `secrets`, `templates`, and `placeholder` option trees are aliases of
the corresponding `sops.*` options, so sops documentation applies directly.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.secret-mgt.enable` | `bool` | `false` | Enable secret management. | Applies the age key and default file/format settings. |
| `cnix-sec.secret-mgt.settings.ageKeyFile` | `str` | `null` | The age key used for encrypting secrets. | Forcibly sets `sops.age.keyFile`. |
| `cnix-sec.secret-mgt.settings.defaultSecretFile` | `path` | `null` | The default secret file to be used for secret management. | Sets `sops.defaultSopsFile`. |
| `cnix-sec.secret-mgt.secrets` | *(alias)* | — | — | Alias of `sops.secrets`. |
| `cnix-sec.secret-mgt.templates` | *(alias)* | — | — | Alias of `sops.templates`. |
| `cnix-sec.secret-mgt.placeholder` | *(alias)* | — | — | Alias of `sops.placeholder`. |

### `home/ssh-port-mgt` — long-lived tunnels

**Enable:** `cnix-sec.ssh-port-mgt.enable`

Declares reverse/forward tunnels as profiles. Each enabled profile becomes a
user service — a `systemd.user.services.<name>` unit on Linux, a
`launchd.agents.<name>` entry on darwin — running `autossh` with
`AUTOSSH_GATETIME=0`, `Restart = "always"`, and a 10 second restart delay. When a
profile sets `passwordFile`, the command is prefixed with
`sshpass -f <path>`.

The module asserts that SSH is enabled, so a tunnel cannot be declared without
the SSH configuration it depends on.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.ssh-port-mgt.enable` | `bool` | `false` | Enable SSH port management. | Installs `autossh`/`sshpass` and generates the profile services. |
| `cnix-sec.ssh-port-mgt.settings.profiles` | `attrsOf <submodule>` | `{ }` | SSH port management profiles. | Declares the named tunnel profiles. |
| `…profiles.<name>.enable` | `bool` | `false` | Enable this SSH port management profile. | Generates the service for this profile. |
| `…profiles.<name>.settings.passwordFile` | `nullOr path` | `null` | Path to the password file for this profile. | Prefixes the command with `sshpass -f <path>`. |
| `…profiles.<name>.settings.autoSSHArgs` | `listOf str` | `[ "-M" "0" "-N" <profileName> ]` | Additional arguments to pass to the SSH command for this profile. | Arguments appended to the `autossh` invocation. |
| `…profiles.<name>.build.services.name` | `str` | `cnix-sec-ssh-port-mgt-<name>` | The name of the built SSH port management profile. | Names the generated systemd/launchd unit. |
| `…profiles.<name>.build.services.value` | `nullOr (attrsOf anything)` | `null` | The built SSH port management profile. | Holds the generated unit definition; read-only in practice. |

### `nixos/default` — system packages and the sops module

Always applies. Imports `sops-nix`'s NixOS module, adds `sops` and `age` to the
system profile, and aliases `cnix-sec.pki` onto `security.pki` so certificate
config sits under the same namespace as everything else here.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.pki` | *(alias of `security.pki`)* | — | — | Configures system certificate authorities through `security.pki`. |

### `nixos/secret-mgt` — system-wide secrets

**Enable:** `cnix-sec.secret-mgt.enable`

The system counterpart of the home module. It asserts that an age key is set,
then forces `sops.age.keyFile`, defaults the format to YAML, enables
`sops.useTmpfs` as a default so secrets never land on disk, and enables systemd
activation so secrets are decrypted early and reliably.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.secret-mgt.enable` | `bool` | `false` | Enable secret management | Applies the sops system configuration; requires an age key. |
| `cnix-sec.secret-mgt.settings.ageKeyFile` | `nullOr str` | `null` | The age key used for encrypting secrets. | Forcibly sets `sops.age.keyFile`; must be set when enabled. |
| `cnix-sec.secret-mgt.settings.defaultSecretFile` | `path` | `null` | The default secret file to be used for secret management. | Sets `sops.defaultSopsFile`. |
| `cnix-sec.secret-mgt.secrets` | *(alias)* | — | — | Alias of `sops.secrets`. |
| `cnix-sec.secret-mgt.templates` | *(alias)* | — | — | Alias of `sops.templates`. |

### `nixos/secure-store` — LUKS-backed volume

**Enable:** `cnix-sec.secure-store.enable`

Registers a LUKS device in initrd and mounts it at `/mnt/<name>`. It asserts both
that a device path was given and that the mount point has a filesystem type, so a
misconfigured store fails at evaluation rather than at boot.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-sec.secure-store.enable` | `bool` | `false` | Enable secure store | Creates the LUKS initrd device and the `/mnt/<name>` filesystem entry. |
| `cnix-sec.secure-store.settings.name` | `str` | `"secure-store"` | The name of the secure store device. | Sets the mapper name and mount path. |
| `cnix-sec.secure-store.settings.luksDevicePath` | `str` | `null` | The path to the LUKS device, e.g. /dev/disk/by-uuid/… | Device registered in `boot.initrd.luks.devices`; required when enabled. |
| `cnix-sec.secure-store.settings.mountPoint.fsType` | `str` | `"ext4"` | The filesystem type for the secure store. | Filesystem type of the mounted volume. |
| `cnix-sec.secure-store.settings.mountPoint.options` | `listOf str` | `[ ]` | Mount options for the secure store filesystem. | Mount options passed to the filesystem entry. |

## Notes

- `secret-mgt` exists in both classes with the same option paths; the home
  variant additionally aliases `sops.placeholder`, the NixOS variant adds
  `useTmpfs` and systemd activation.
- The `home/default` and `nixos/default` modules are not enable-gated: importing
  them brings sops and age packages into the respective profiles.
- There is no `darwin` module directory, although the flake wires `sops-nix`'s
  darwin module for consuming configurations.
