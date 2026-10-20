---
title: cirius-security
sidebar_position: 2
description: Secrets, SSH clients and servers, tunnels, firewall rules, application confinement, and hardware authentication.
---

# cirius-security

`cirius-security` exposes security configuration under `cnix-sec`. It provides
Home Manager and NixOS modules. Importing the default module installs `sops` and
`age`; each other capability requires its own enable option.

The modules configure existing Home Manager, NixOS, and sops-nix services. Native
options remain available for settings that the facade does not expose. The
flake pins Home Manager for its checks; consuming homes use their own Home
Manager configuration.

## Modules

| Module | Class | Enable option | Configures |
| --- | --- | --- | --- |
| `default` | home | `ssh.enable` for SSH | SOPS/age packages, SSH client, agent, declared host keys |
| `secret-mgt` | home | `secret-mgt.enable` | SOPS identities, secrets, templates |
| `ssh-port-mgt` | home | `ssh-port-mgt.enable` | autossh user services and launchd agents |
| `default` | nixos | Always imported | SOPS/age packages, `pki` and placeholder aliases |
| `secret-mgt` | nixos | `secret-mgt.enable` | System secrets and activation |
| `secure-store` | nixos | `secure-store.enable` | Existing LUKS device and filesystem mount |
| `sshd` | nixos | `sshd.enable` | SSH server and authentication policy |
| `firewall` | nixos | `firewall.enable` | Global and interface-specific allowed ports |
| `fail2ban` | nixos | `fail2ban.enable` | Log-based bans and custom jails |
| `apparmor` | nixos | `apparmor.enable` | Application confinement policies |
| `u2f` | nixos | `u2f.enable` | Hardware authentication for selected PAM services |
| `usbguard` | nixos | `usbguard.enable` | USB device authorization |

All paths in the following tables start with `cnix-sec`. New capability enable
options default to `false`. Setting a facade enable option to `false` does not
disable a service enabled by another module.

## Home Manager: SSH

```nix
{ inputs, config, ... }:
{
  imports = [ inputs.cirius-security.homeModules.default ];

  cnix-sec.ssh = {
    enable = true;
    agent.maximumIdentityLifetime = 3600;
    settings = {
      "*" = {
        ForwardAgent = false;
        HashKnownHosts = true;
        StrictHostKeyChecking = "ask";
      };
      "git.example.org" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
    };
  };
}
```

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `ssh.enable` | bool | `false` | Enable the SSH client and configured agent behavior. |
| `ssh.agent.enable` | bool | `true` | Start OpenSSH's agent when SSH is enabled. Set to `false` for an external agent. |
| `ssh.agent.maximumIdentityLifetime` | null or positive integer | `28800` | Key lifetime in seconds; `null` removes the limit. |
| `ssh.settings` | Home Manager SSH settings | `{ }` | Host/Match blocks, including Home Manager DAG ordering. |
| `ssh.knownHosts` | list of single-line strings | `[ ]` | Public known_hosts entries in `~/.ssh/cnix_known_hosts`. |
| `ssh.additionalConfigPaths` | list of strings | `[ ]` | Additional SSH configuration files to include. |

When declared host keys are present, the default `UserKnownHostsFile` searches
both the writable `~/.ssh/known_hosts` and the managed `~/.ssh/cnix_known_hosts`.
Supply complete entries, such as `host.example ssh-ed25519 <public-key>`, after
verifying the key through a trusted channel. A custom `UserKnownHostsFile` must
include the managed file if it should remain in use. These public entries enter
the Nix store.

The client disables Home Manager's default SSH settings and defaults
`AddKeysToAgent` to `yes`. Override it through `ssh.settings`. A GnuPG SSH agent
requires `ssh.agent.enable = false`; a check rejects the conflicting facade
configuration. Other external agents must supply their own socket environment.
Do not include the generated `~/.ssh/config` in `additionalConfigPaths`.

See [OpenSSH client options](https://man.openbsd.org/ssh_config).

## Home Manager: tunnels

```nix
cnix-sec.ssh-port-mgt = {
  enable = true; # Also requires cnix-sec.ssh.enable.
  settings.profiles.database = {
    enable = true;
    settings = {
      host = "database-gateway"; # An SSH host alias.
      identityFile = "/home/me/.ssh/database-tunnel";
      localForwards = [
        { port = 15432; destinationHost = "127.0.0.1"; destinationPort = 5432; }
      ];
    };
  };
};
```

The service uses noninteractive authentication when `settings.host` is set.
Provision its private key and trusted host key before starting the service. An
expiring interactive agent key cannot guarantee unattended reconnection.

| Option | Type | Default |
| --- | --- | --- |
| `ssh-port-mgt.enable` | bool | `false` |
| `ssh-port-mgt.settings.profiles` | attribute set of profiles | `{ }` |
| `…profiles.<name>.enable` | bool | `false` |
| `…profiles.<name>.settings.host` | null or SSH host string | `null` |
| `…profiles.<name>.settings.identityFile` | null or string | `null` |
| `…profiles.<name>.settings.localForwards` | list of forwarding records | `[ ]` |
| `…profiles.<name>.settings.remoteForwards` | list of forwarding records | `[ ]` |
| `…profiles.<name>.settings.serverAliveInterval` | unsigned integer | `30` seconds |
| `…profiles.<name>.settings.serverAliveCountMax` | positive integer | `3` |
| `…profiles.<name>.settings.exitOnForwardFailure` | bool | `true` |
| `…profiles.<name>.settings.passwordFile` | null or path | `null` |
| `…profiles.<name>.settings.autoSSHArgs` | list of strings | Generated arguments; see below. |
| `…profiles.<name>.build.services.name` | string | `cnix-sec-ssh-port-mgt-<name>` |
| `…profiles.<name>.build.services.value` | null or attribute set | Generated service definition. |

Each forwarding record has these fields:

| Field | Type | Default | Effect |
| --- | --- | --- | --- |
| `bindAddress` | string | `127.0.0.1` | Listener address. |
| `port` | TCP port | Required | Listener port. |
| `destinationHost` | string | `127.0.0.1` | Destination host. |
| `destinationPort` | TCP port | Required | Destination port. |

Local forwards listen on this machine and reach destinations through the server.
Remote forwards listen on the server and reach destinations through this machine.
IPv6 addresses are bracketed in generated arguments. Server policy can restrict
remote forwarding and bind addresses.

Without `host`, the argument default remains
`[ "-M" "0" "-N" "cnix-sec-ssh-port-mgt-<name>" ]`. Typed identities or forwards
require `host`. With `host`, the module adds `BatchMode=yes`, keepalives, forwarding
failure behavior, and the declared identity/forwards. An explicit `autoSSHArgs`
replaces the complete generated list. It remains the escape hatch for existing
configurations and password authentication through `passwordFile`; typed mode's
`BatchMode=yes` does not permit password prompts.

Linux services restart after 10 seconds and set `AUTOSSH_GATETIME=0`. Darwin
agents use an argument array, the same environment variable, and `KeepAlive`.
Private keys and password files must remain outside the Nix store. Use runtime
path strings rather than Nix file literals for private material.

## Home Manager and NixOS: secrets

```nix
cnix-sec.secret-mgt = {
  enable = true;
  settings = {
    ageKeyFile = "/var/lib/sops-nix/key.txt"; # Use a home path for Home Manager.
    generateAgeKey = true;
    defaultSecretFile = ./secrets.yaml; # Encrypted SOPS file.
  };
  secrets."service-token" = { };
};
```

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `secret-mgt.enable` | bool | `false` | Apply SOPS defaults. |
| `secret-mgt.settings.ageKeyFile` | null or runtime path | `null` | Default age identity file; store paths are rejected by SOPS. |
| `secret-mgt.settings.ageSSHKeyPaths` | null or list of paths | `null` | SSH keys used as age identities. Null preserves upstream discovery; `[ ]` disables it. |
| `secret-mgt.settings.generateAgeKey` | bool | `false` | Generate a missing identity at the configured key-file path. |
| `secret-mgt.settings.defaultSecretFormat` | SOPS format enum | `"yaml"` | Default format, such as YAML or JSON. |
| `secret-mgt.settings.defaultSecretFile` | null or path | `null` | Optional default encrypted file; individual secrets can select their own files. |
| `secret-mgt.secrets` | alias | — | `sops.secrets`. |
| `secret-mgt.templates` | alias | — | `sops.templates`. |
| `secret-mgt.placeholder` | alias | — | `sops.placeholder`. |

A generated age key does not automatically update the encrypted file's recipients.
Add its public recipient to your SOPS policy and update encrypted files separately.
SOPS checks that a usable key source is configured when secrets are declared.
Key generation additionally requires `sops.age.keyFile` to be set.

The NixOS module defaults to tmpfs and enables systemd activation. Tmpfs does not
provide a general guarantee against writes to unencrypted swap; review swap
configuration if it is enabled. Back up recovery keys separately.

Existing `ageKeyFile` configurations continue to work. The facade now uses a
default instead of forcing `sops.age.keyFile`, so an explicit native SOPS value
can override it. Home Manager additionally supports its own native GnuPG options.
See [sops-nix](https://github.com/Mic92/sops-nix).

## NixOS: SSH server and firewall

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-security.nixosModules.default ];
  cnix-sec = {
    sshd = {
      enable = true;
      settings.AllowUsers = [ "me" ];
    };
    firewall = {
      enable = true;
      interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
  };
  # Configure the user's authorized SSH keys separately.
}
```

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `sshd.enable` | bool | `false` | Enable the server and facade defaults. |
| `sshd.ports` | list of ports | `[ 22 ]` | Server listening ports. |
| `sshd.openFirewall` | bool | `false` | Open the server ports globally when true. |
| `sshd.settings` | NixOS OpenSSH settings | `{ }` | Additional settings and overrides. |
| `firewall.enable` | bool | `false` | Enable the NixOS firewall. |
| `firewall.allowedTCPPorts` | list of ports | `[ ]` | Globally allowed TCP ports. |
| `firewall.allowedUDPPorts` | list of ports | `[ ]` | Globally allowed UDP ports. |
| `firewall.interfaces` | NixOS firewall interface records | `{ }` | Per-interface allowed ports and ranges. |

When enabled, the SSH server defaults to no root login, no password or
keyboard-interactive authentication, and no X11 forwarding. Override these
settings explicitly when needed, including keyboard-interactive authentication
for a PAM-based SSH MFA setup. Verify authorized keys before switching a remote
host to key-only access.

`cirius-networking` can also enable `services.openssh`. Its enable setting composes
with this module; this change does not move service ownership. Firewall lists
merge with other modules. Empty lists do not close ports opened elsewhere. A
native `services.openssh.openFirewall = true` overrides the facade default and
opens SSH globally. Interface rules do not restrict the daemon's listening
addresses; use `services.openssh.listenAddresses` if needed.

## NixOS: intrusion prevention and confinement

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `fail2ban.enable` | bool | `false` | Enable Fail2ban; requires the NixOS firewall or nftables. |
| `fail2ban.settings.bantime` | string | `"10m"` | Ban duration. |
| `fail2ban.settings.maxretry` | unsigned integer | `3` | Failed attempts before a ban. |
| `fail2ban.settings.ignoreIP` | list of strings | `[ ]` | Additional exempt addresses/networks. |
| `fail2ban.jails` | NixOS Fail2ban jails | `{ }` | Jail/filter configuration. NixOS provides SSH jail defaults. |
| `apparmor.enable` | bool | `false` | Enable AppArmor. Kernel activation can require a reboot. |
| `apparmor.policies` | NixOS AppArmor policy records | `{ }` | Named policies with `state`, `profile` or `path`. |
| `apparmor.packages` | list of packages | `[ ]` | Packages supplying AppArmor includes. |

Fail2ban relies on service logs and matching filters. It does not replace
key-based authentication. AppArmor covers processes with loaded policies;
installing include files does not establish confinement. Start new policies in
`complain` mode if you need to observe access before enforcing them. Supported
policy states are `disable`, `complain`, and `enforce`.

## NixOS: hardware authentication and USB authorization

```nix
cnix-sec.u2f = {
  enable = true;
  services.sudo = "required";
  settings = { authfile = "/etc/u2f-mappings"; cue = true; };
};
# Provision the enrollment file before activation. Keep a recovery path.
```

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `u2f.enable` | bool | `false` | Enable configuration for selected PAM services. |
| `u2f.services` | attribute set of PAM control enums | `{ }` | Map service names to `required`, `requisite`, `sufficient`, or `optional`. Must be non-empty when enabled. |
| `u2f.settings` | NixOS pam-u2f settings | `{ }` | `authfile`, `cue`, and other native settings. |
| `usbguard.enable` | bool | `false` | Enable USBGuard. |
| `usbguard.rules` | null or lines | `null` | Explicit non-empty device policy. |
| `usbguard.ruleFile` | null or path | `null` | Runtime policy-file alternative. |
| `usbguard.IPCAllowedUsers` | list of strings | `[ "root" ]` | Users permitted to control the daemon. |

U2F configuration applies only to named PAM services; it does not enable U2F
globally. `required` adds a required factor to the service's existing stack;
`sufficient` can allow the token to replace a password. Enroll a working token
and a recovery method before enforcement. Native global PAM settings can still
enable U2F on other services.

USBGuard requires exactly one of non-empty `rules` or `ruleFile`. Generate a
candidate policy with `usbguard generate-policy`, review it, and include the
keyboard, mouse, docks, and security tokens you need. Provision a runtime policy
file before activation when using `ruleFile`. Devices without an allow rule are
blocked by upstream defaults. The module does not inventory or enroll devices.

## NixOS: encrypted store and certificates

| Option | Type | Default | Effect |
| --- | --- | --- | --- |
| `secure-store.enable` | bool | `false` | Register an existing encrypted volume at boot. |
| `secure-store.settings.name` | string | `"secure-store"` | Mapper name and `/mnt/<name>` mount directory. |
| `secure-store.settings.luksDevicePath` | null or string | `null` | Required existing LUKS device, preferably by UUID. |
| `secure-store.settings.mountPoint.fsType` | string | `"ext4"` | Filesystem type. |
| `secure-store.settings.mountPoint.options` | list of strings | `[ ]` | Filesystem mount options. |
| `pki` | alias | — | `security.pki` certificate configuration. |

The store module does not format disks, create LUKS headers, or manage recovery
keys. No dedicated nix-darwin system security modules are supplied; Home Manager
SSH and tunnel configuration supports Darwin.

## Validation

From the repository root:

```sh
# Module evaluation, invalid configurations, generated SSH config, and VM tests.
nix flake check path:./flakes/cirius-security

# Fast module checks only.
nix build --no-link path:./flakes/cirius-security#checks.x86_64-linux.modules

# Two-VM SSH, firewall, Fail2ban, and loaded AppArmor policy checks. Requires KVM.
nix build --no-link path:./flakes/cirius-security#checks.x86_64-linux.host-protection
```

The tests do not enroll hardware tokens, attach USB devices, decrypt production
secrets, or activate changes on your machine.
