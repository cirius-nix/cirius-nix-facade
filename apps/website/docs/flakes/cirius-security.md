---
title: cirius-security
sidebar_position: 2
description: Simple defaults for secrets, SSH, persistent tunnels, and host protection.
---

# cirius-security

Import the default Home Manager or NixOS module, then enable the concerns you
need. Use upstream options for advanced configuration. The consumer flake adds
no Home Manager test dependency.

## Home Manager

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-security.homeModules.default ];
  cnix-sec.ssh.enable = true;
}
```

SSH starts an agent with an eight-hour key lifetime and defaults `AddKeysToAgent`
to `yes`. If GnuPG already supplies the SSH agent, the facade uses that agent.
Host settings and agent overrides use their normal upstream paths:

```nix
services.ssh-agent.defaultMaximumIdentityLifetime = 3600;
programs.ssh.settings."git.example.org" = {
  User = "git";
  IdentityFile = "~/.ssh/id_ed25519";
  IdentitiesOnly = true;
};
```

### Persistent tunnels

```nix
cnix-sec.ssh-port-mgt = {
  enable = true; # Enables the SSH client dependency automatically.
  settings.profiles.database.enable = true;
};
programs.ssh.settings."cnix-sec-ssh-port-mgt-database" = {
  HostName = "gateway.example.org";
  User = "me";
  LocalForward = [ "127.0.0.1:15432 127.0.0.1:5432" ];
};
```

Each profile connects to the SSH alias `cnix-sec-ssh-port-mgt-<name>`. Configure
its host, identity, and forwarding with `programs.ssh.settings`. There is no
second host or forwarding schema.

Default autossh arguments disable the monitoring port, skip a remote command,
send keepalives every 30 seconds, disconnect after three unanswered keepalives,
and exit when a forwarding listener cannot be established. Linux services
restart after 10 seconds. Darwin agents use `KeepAlive`. Both set
`AUTOSSH_GATETIME=0`. Provision authentication and trusted host keys for unattended
reconnection.

The existing `settings.autoSSHArgs` profile option replaces the complete argument
list for advanced connections. Existing explicit lists are unchanged. The
existing `settings.passwordFile` option uses `sshpass`; keep private files outside
the Nix store and refer to them with runtime path strings.

## NixOS

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-security.nixosModules.default ];
  cnix-sec = {
    sshd.enable = true;
    firewall.enable = true;
    fail2ban.enable = true;
  };
}
```

Each new module exposes only `enable`, defaulting to `false`:

| Option | Result when enabled | Advanced configuration |
| --- | --- | --- |
| `cnix-sec.sshd.enable` | Start OpenSSH with NixOS defaults, including its normal firewall opening. | `services.openssh.*` |
| `cnix-sec.firewall.enable` | Enable the NixOS firewall. Existing service rules still apply. | `networking.firewall.*` |
| `cnix-sec.fail2ban.enable` | Enable Fail2ban and default the firewall on. NixOS supplies jail defaults for services such as SSH. Does not enable SSH itself. | `services.fail2ban.*` |

The facade inherits NixOS authentication defaults. Configure account passwords or
authorized SSH keys normally. It does not impose an additional key-only login
policy or require manual firewall wiring before the default SSH service works.
`cirius-networking` can also enable OpenSSH; both settings compose.

For example, restrict SSH to a selected interface using native options:

```nix
services.openssh.openFirewall = false;
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
```

AppArmor, U2F, and USBGuard use native options directly:
`security.apparmor.*`, `security.pam.*`, and `services.usbguard.*`.
The facade supplies no generic enforcement presets because application policies,
token enrollment, and USB authorization depend on the machine.

## Secrets and encrypted storage

`cnix-sec.secret-mgt.enable` applies YAML defaults to SOPS. The NixOS variant
also defaults to tmpfs and enables systemd activation. Configure encrypted files
and identities through `sops.*`:

```nix
cnix-sec.secret-mgt.enable = true;
sops = {
  defaultSopsFile = ./secrets.yaml; # Encrypted file.
  age.keyFile = "/var/lib/sops-nix/key.txt"; # Use a home path in Home Manager.
  secrets."service-token" = { };
};
```

Use native `sops.age.sshKeyPaths`, `sops.age.generateKey`, and
`sops.defaultSopsFormat` when needed. Generating an identity does not update the
encrypted file's recipients. Tmpfs does not guarantee that secrets never reach
unencrypted swap. See [sops-nix](https://github.com/Mic92/sops-nix).

Existing facade interfaces remain compatible:

| Existing option | Default | Purpose |
| --- | --- | --- |
| `ssh.additionalConfigPaths` | `[ ]` | Extra SSH config files to include. Avoid including the generated `~/.ssh/config` itself. |
| `secret-mgt.settings.ageKeyFile` | `null` | Optional default identity path; native SOPS settings can override it. |
| `secret-mgt.settings.defaultSecretFile` | `null` | Optional default encrypted file. |
| `secret-mgt.secrets`, `.templates`, `.placeholder` | Upstream | Existing SOPS aliases. Prefer `sops.*` in new configuration. |
| `secure-store.enable` (NixOS) | `false` | Mount an existing LUKS volume. Requires its real device path. |
| `secure-store.settings.name` | `"secure-store"` | Mapper name and `/mnt/<name>` mount directory. |
| `secure-store.settings.luksDevicePath` | `null` | Existing device, preferably by UUID. |
| `secure-store.settings.mountPoint.fsType` | `"ext4"` | Filesystem type. |
| `secure-store.settings.mountPoint.options` | `[ ]` | Filesystem mount options. |
| `pki` (NixOS) | Upstream | Existing alias of `security.pki`. |

Importing the default module still installs `sops` and `age`. The store module
does not format disks or create encryption keys. There are no dedicated
nix-darwin system modules; Home Manager SSH and tunnels support Darwin.

## Migration from the expanded API

The temporary SSH agent, host-key, settings, firewall, jail, policy, hardware,
and SOPS pass-through options are removed. Configure their upstream paths as
shown above. Typed tunnel fields are removed; use a normal SSH alias or the
existing raw argument option. Reconnect defaults are internal settings.

## Development checks

From the repository root:

```sh
nix flake check path:./flakes/cirius-security
nix build --impure --no-link --file flakes/cirius-security/tests modules ssh-config host-protection
```

The second command loads the development-only Home Manager revision pinned in
`tests/default.nix`. It checks enable-only configurations, native overrides,
legacy secret and tunnel configuration, OpenSSH parsing, and Darwin tunnel
configuration. The two-VM test verifies SSH access, firewall filtering, and
Fail2ban bans. It requires KVM. No host configuration is activated.
