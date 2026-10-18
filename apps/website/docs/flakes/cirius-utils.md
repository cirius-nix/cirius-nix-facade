---
title: cirius-utils
sidebar_position: 1
description: Base home and NixOS modules — package manager, desktop environment behaviour, shortcuts, power controls, web apps, and connectivity.
---

# cirius-utils

The base layer every host is likely to want: the package manager, the desktop
environment's behaviour and shortcuts, and the small conveniences that make a
Linux desktop pleasant without being bespoke. This is also the flake that holds
the cross-cutting `settings` options other modules read.

| | |
| --- | --- |
| Namespace | `cnix-utils` |
| Module classes | `home`, `nixos` |
| External inputs | `nix-flatpak`, `plasma-manager`, `cirius-lib` |
| Options | 37 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-utils.homeModules.default ];

  cnix-utils.enable = true;
  cnix-utils.settings.managedDesktopEnvironment = "kde";
  cnix-utils.package-manager.flatpak.enable = true;
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | `cnix-utils.enable` | Base packages, fish abbrs, desktop-environment behaviour |
| `package-manager` | home | `cnix-utils.package-manager.flatpak.enable` | Flatpak remotes, packages, overrides |
| `desktop-environment.shortcuts` | home | `...shortcuts.enable` | KDE/GNOME keybindings |
| `desktop-environment.power-controls` | home | `...power-controls.enable` | KDE power/suspend settings |
| `chrome-webapps` | home | `cnix-utils.chrome-webapps.enable` | Chromium web-app desktop entries |
| `connectivity` | home | `cnix-utils.connectivity.enable` *(default `true`)* | KDE Connect, Syncthing |
| `default` | nixos | *(always applies)* | System level helpers |

### `home/default` — base layer

**Enable:** `cnix-utils.enable`

Installs `nh` and sets up the NixOS-adjacent conveniences most hosts want. With
`settings.dotFileDir` set, it registers fish abbreviations for the whole
switch/build/boot/garbage-collection cycle (`nix-sw`, `nix-rb`, `nix-b`,
`nix-ls-gen`, `nix-del-gens`, `nix-clean-store`) against that flake directory.
`settings.enableBootLogCapture` adds a `$XDG_STATE_HOME/boot-logs` activation and
a `make-boot-log` abbr.

It also normalises desktop-environment behaviour, driven by
`settings.managedDesktopEnvironment`: for KDE it sets Plasma window
position memory, middle-click paste, click-to-select, logout confirmation, and
session restore; for GNOME it fixes keyboard repeat timing through dconf.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-utils.enable` | `bool` | `false` | Enable Cirius Utils. | Master switch for the base home module. |
| `cnix-utils.settings.dotFileDir` | `nullOr str` | `null` | The directory where dotfiles are stored. If null, defaults to ~/.dotfiles. | Defines the `nix-*` fish abbrs that operate on this directory. |
| `cnix-utils.settings.enableBootLogCapture` | `bool` | `false` | Enable boot log capture. | Adds the boot-log directory activation and `make-boot-log` abbr. |
| `cnix-utils.settings.managedDesktopEnvironment` | `enum [ "unset" "kde" "gnome" ]` | `"unset"` | The desktop environment to manage. If unset, will not manage any desktop environment. | Selects which DE-specific block applies, here and in the shortcuts and power-controls modules. |

### `home/package-manager` — flatpak

**Enable:** `cnix-utils.package-manager.flatpak.enable` — an alias of
`services.flatpak.enable`, so setting either name is the same thing.

Installs flatpak, registers each `remotePackages` entry as a remote, installs the
declared packages, enables weekly automatic updates, and — deliberately — strips
X11 access while keeping Wayland access and cursor themes working
(`Context.sockets = [ "wayland" "!x11" "!fallback-x11" ]`). A `flathub` remote is
registered by the module itself, so a host only has to list packages.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-utils.package-manager.flatpak.enable` | `bool` (alias of `services.flatpak.enable`) | `false` | — | Turns the flatpak configuration on. |
| `cnix-utils.package-manager.flatpak.remotePackages` | `attrsOf <submodule>` | `{ }` | A set of remote repositories and their packages to be installed. | Each attribute becomes a flatpak remote and contributes its packages. |
| `…remotePackages.<name>.location` | `str` | — | The URL of the remote repository. | Remote repository URL registered with flatpak. |
| `…remotePackages.<name>.packages` | `listOf str` | `[ ]` | A list of package IDs to be installed from the remote repository. | Package app-IDs requested from this remote. |
| `…remotePackages.<name>.builtPackages` | `listOf (attrsOf str)` *(read-only)* | — | A list of package IDs to be built from the remote repository. | Computed `{ appId, origin }` list passed to flatpak. |

### `home/desktop-environment/power-controls` — power behaviour

**Enable:** `cnix-utils.desktop-environment.power-controls.enable`

Applies recommended screen-off and suspend behaviour on AC power. Only acts when
`settings.managedDesktopEnvironment = "kde"` — the settings are written to
`programs.plasma.powerdevil.AC`.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `…power-controls.enable` | `bool` | `false` | Whether to enable recommended power controls for the system for KDE or GNOME. | Applies the powerdevil settings below. |
| `…power-controls.settings.onAC.offDisplayTimeout` | `int` | `600` | The time in seconds before the display turns off when on AC power. | `powerdevil.AC.turnOffDisplay.idleTimeout`. |
| `…power-controls.settings.onAC.sleep.action` | `enum [ "sleep" "hibernate" "nothing" "shutdown" ]` | `"sleep"` | The action to take when the system is idle on AC power. | `powerdevil.AC.autoSuspend.action`. |
| `…power-controls.settings.onAC.sleep.timeout` | `int` | `1800` | The time in seconds before the system goes to sleep when on AC power. | `powerdevil.AC.autoSuspend.idleTimeout`. |

### `home/desktop-environment/shortcuts` — consistent keybindings

**Enable:** `cnix-utils.desktop-environment.shortcuts.enable`

One canonical table of keybindings, translated into KDE Plasma shortcuts or GNOME
dconf keys depending on `settings.managedDesktopEnvironment`. The translation
tables live in private `_*.nix` files next to the module (`_kde.action.nix`,
`_kde.modifier.nix`, `_kde.key.nix`, `_gnome.action.nix`,
`_gnome.modifier.nix`), and the recommended set lives in
`_default.bindings.nix`.

`useRecommendedShortcuts` swaps in that recommended set; it asserts that a
desktop environment is actually managed, so it cannot silently do nothing.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `…shortcuts.enable` | `bool` | `false` | Whether to enable recommended shortcuts for the system for KDE or GNOME. | Applies the translated shortcuts. |
| `…shortcuts.useRecommendedShortcuts` | `bool` | `false` | Whether to use recommended shortcuts for the system for KDE or GNOME. This will apply a consistent set of shortcuts across applications and the desktop environment itself. | Replaces `settings.bindings` with the built-in default table. |
| `…shortcuts.settings.bindings` | `attrsOf (listOf (listOf str))` | `{ }` | Keybindings for the recommended shortcuts. Each keybinding is a list of keys. | Canonical action → key sequence table, e.g. `{ "desktop.overview" = [ "SUPER" ]; }`. |
| `…shortcuts.settings.extendedActions.kde` | `attrsOf str` | `{ }` | Additional KDE actions to be added to the default set of actions. | Deep-merged over the built-in KDE action table. |
| `…shortcuts.settings.extendedActions.gnome` | `attrsOf str` | `{ }` | Additional GNOME actions to be added to the default set of actions. | Deep-merged over the built-in GNOME action table. |

### `home/chrome-webapps` — browser apps as desktop entries

**Enable:** `cnix-utils.chrome-webapps.enable`

Turns sites into first-class desktop entries: for every workspace and app it
writes an `xdg.desktopEntries` entry running the browser with
`--user-data-dir=<workspaceDataPath>/<workspace> --app=<url>`, so each workspace
gets an isolated profile and each app gets its own window class.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-utils.chrome-webapps.enable` | `bool` | `false` | Enable Chrome Web Apps. | Installs the browser and writes the desktop entries. |
| `…chrome-webapps.settings.package` | `package` | `pkgs.chromium` | The package name of the Chrome browser to be used. | Browser used as the exec target and installed into the profile. |
| `…chrome-webapps.settings.workspaceDataPath` | `path` | — | The path to the workspace data directory for Chrome Web Apps. | Base directory for each workspace's `--user-data-dir`; required to use the module. |
| `…chrome-webapps.settings.workspaces` | `attrsOf <submodule>` | `{ }` | A set of workspaces for Chrome Web Apps, it shared the user data directory with the main Chrome browser. | Declares the workspaces and their apps. |
| `…workspaces.<name>.apps` | `attrsOf <submodule>` | `{ }` | A set of Chrome Web Apps to be installed in the workspace. | Declares the apps in this workspace. |
| `…apps.<name>.url` | `str` | — | The URL of the Chrome Web App. | The `--app=` target. |
| `…apps.<name>.categories` | `listOf str` | `[ ]` | A list of categories for the Chrome Web App. | Desktop-entry categories. |
| `…apps.<name>.genericName` | `str` | — | A generic name for the Chrome Web App. | Desktop-entry generic name. |
| `…apps.<name>.comment` | `str` | — | A description of the Chrome Web App. | Desktop-entry comment. |
| `…apps.<name>.icon` | `nullOr path` | `null` | The path to the icon for the Chrome Web App. | Desktop-entry icon. |
| `…apps.<name>.className` | `str` | — | The class name for the Chrome Web App. | Sets the window class so the entry groups correctly. |

### `home/connectivity` — KDE Connect and Syncthing

**Enable:** `cnix-utils.connectivity.enable` — **defaults to `true`**, so it
applies as soon as the module is imported. Set it to `false` to opt out.

Installs KDE Connect, and when `settings.fileSync.enable` is set it configures
Syncthing with a local GUI address, credentials from a password file, and device
and folder tables passed straight through to `services.syncthing`. The GUI theme
is only a `lib.mkDefault`, so it is easy to override.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-utils.connectivity.enable` | `bool` | `true` | Enable connectivity configuration. | Installs KDE Connect and gates the Syncthing block. |
| `…connectivity.settings.fileSync.enable` | `bool` | `true` | Enable file synchronization. | Enables and configures `services.syncthing`. |
| `…fileSync.settings.port` | `int` | `8384` | Port for the file synchronization service. | Syncthing GUI address port. |
| `…fileSync.settings.devices` | `json` | `{ }` | A set of devices to be used by syncthing. Each device should have an id attribute. | Passed to `services.syncthing.settings.devices`. |
| `…fileSync.settings.folders` | `json` | `{ }` | A set of folders to be synced by syncthing. Each folder should have an id attribute and a devices attribute which is a list of device ids. | Passed to `services.syncthing.settings.folders`. |
| `…fileSync.settings.credentials.username` | `str` | `"admin"` | Username for the file synchronization service. | Syncthing GUI username. |
| `…fileSync.settings.credentials.passwordFile` | `nullOr path` | `null` | Path to the password file for the file synchronization service. | Syncthing GUI password file (kept out of the store). |

### `nixos/default` — KDE Wallet from LUKS

The flake's only system-level module, and single-purpose: unlock the KDE wallet
with the LUKS passphrase already entered at boot. It asserts that Plasma 6 is
enabled before touching PAM, so it fails loudly instead of half-applying.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-utils.unlockKDEWalletByLUKS` | `bool` | `false` | Whether to unlock the KDE Wallet by LUKS. | Wires `pam_systemd_loadkey` into the Plasma login PAM stack and sets `KeyringMode = "inherit"`. |

## Notes

- `connectivity` is the one module that is on by default — importing
  `homeModules.default` and enabling `cnix-utils.enable` is enough to get KDE
  Connect and Syncthing.
- `chrome-webapps.settings.workspaceDataPath` has no default; a Chrome Web Apps
  configuration is incomplete without it.
- Options built through `cnix-lib.mkStrOpt` without an explicit default (for
  example `remotePackages.<name>.location`) declare no default at all rather than
  `null`, so NixOS reports them as unset until you provide a value.
