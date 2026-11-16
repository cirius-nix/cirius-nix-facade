---
title: cirius-visual
sidebar_position: 4
description: Desktop selection for KDE Plasma, GNOME, and COSMIC, with shared application styling and desktop-specific settings.
---

# cirius-visual

The desktop layer selects KDE Plasma, GNOME, or COSMIC. Stylix provides shared
application styling and fonts. KDE and GNOME have additional desktop settings;
KDE also has panels, window decorations, and a scheduled light/dark theme switcher.
COSMIC uses its native desktop settings and theme.

| | |
| --- | --- |
| Namespace | `cnix-visual` |
| Module classes | `home`, `nixos` |
| External inputs | `stylix`, `plasma-manager`, `kwin-effects-glass`, `kde-audio-vis`, `cirius-lib` |
| Options | 27 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-visual.homeModules.default ];

  cnix-visual.enable = true;
  cnix-visual.useRecommendedFonts = true;
  cnix-visual.useRecommendedTheme = true;
  cnix-visual.desktop-environment.use = "kde";
}
```

`desktop-environment.use` is declared separately in NixOS and Home Manager.
Set both values to the same desktop. If you use `cirius-utils`, also set
`cnix-utils.settings.managedDesktopEnvironment` in Home Manager.

### Select COSMIC

Import `inputs.cirius-visual.nixosModules.default` on the system side and the
existing visual/utils Home Manager modules on the user side. Select COSMIC with:

```nix
# In your NixOS configuration, using your existing Home Manager user:
cnix-visual.desktop-environment.use = "cosmic";
home-manager.users.cirius = {
  cnix-visual.desktop-environment.use = "cosmic";
  cnix-utils.settings.managedDesktopEnvironment = "cosmic";
};
```

If your Home Manager configuration lives in a separate file, set its two options
there instead. Do not add a second user. No COSMIC-specific Home Manager input
is needed. Recommended KDE/GNOME shortcuts, power controls, screen edges, and
workspace settings do not configure COSMIC; use COSMIC Settings for these.
The existing shared application and font settings remain available.

The current `cirius-nix-v4` consumer selects `mht-home-pc` in these files:

- `systems/x86_64-linux/mht-home-pc/default.nix`: the NixOS visual selector.
- `homes/x86_64-linux/cirius@mht-home-pc/default.nix`: the Home Manager visual
  selector and utils selector.

After the facade change is merged, update both consumer inputs, then set the
three selectors above. The input update changes the consumer lock file; review
that diff before switching.

This host also enables `cnix-utils.unlockKDEWalletByLUKS` whenever the secure
store is enabled. Make that existing assignment conditional on Plasma before
selecting COSMIC or GNOME:

```nix
cnix-utils.unlockKDEWalletByLUKS =
  config.cnix-sec.secure-store.enable
  && config.services.desktopManager.plasma6.enable;
```

This keeps the LUKS wallet integration on KDE and avoids its Plasma-only assertion
on other desktops.

```sh
cd /home/cirius/Workspaces/personal/dotfiles/cirius-nix-v4
nix flake update cirius-visual cirius-utils

# Build the selected configuration without activating it.
nix build .#nixosConfigurations.mht-home-pc.config.system.build.toplevel --out-link result-cosmic

# Activate only when you are ready to test the new desktop.
sudo nixos-rebuild switch --flake .#mht-home-pc
```

The display-manager change can end your graphical session. Save your work before
switching. To return to KDE, set all three selectors to `"kde"`, then run:

```sh
nix build .#nixosConfigurations.mht-home-pc.config.system.build.toplevel --out-link result-kde
sudo nixos-rebuild switch --flake .#mht-home-pc
```

Use `"gnome"` in all three places to select GNOME instead. If the new session
cannot start, use a text console to restore the selectors and rebuild, or boot
the previous NixOS generation.

KDE is the original desktop for `mht-home-pc`, and its full host derivation
evaluates successfully. During COSMIC validation, the full GNOME host evaluation failed on the existing
`gnome.profile-default.dockPosition` reference in the GNOME Home Manager module.
The unchanged consumer inputs fail at the same reference. The standalone GNOME
system module evaluates successfully, but this host needs that Home Manager
issue resolved before switching to GNOME.

COSMIC and its greeter are included in NixOS since 25.05. The checked
nixos-unstable pin already contains them; no input upgrade or external COSMIC
flake is required. The facade enables the two services documented by the
[official NixOS wiki](https://wiki.nixos.org/wiki/COSMIC) and
[COSMIC upstream](https://github.com/pop-os/cosmic-epoch#installing-on-nixos).
Upstream supplies the session, portals, Xwayland, greeter service account, graphics,
and shared audio defaults. Existing host NVIDIA and PipeWire settings are reused.
NVIDIA/Wayland behaviour, suspend, screen sharing, and application theme behaviour
still require testing on the target machine. This module does not apply the KDE
theme, wallpaper, or theme switcher to COSMIC.

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | `cnix-visual.enable` | Stylix base16 scheme, fonts, Kvantum |
| `desktop-environment` | home | `cnix-visual.desktop-environment.use` | Plasma/GNOME base, wallpaper, app theming |
| `desktop-environment.gnome` | home | `…use == "gnome"` | GNOME extensions and dconf |
| `desktop-environment.kde` | home | `…use == "kde"` | KDE theming, fonts, theme switcher |
| `desktop-environment.kde.panels` | home | `…useRecommendedTheme` | Panel layout |
| `desktop-environment` | nixos | `…use` *(same option path)* | DE services |
| `desktop-environment.kde` | nixos | `…use == "kde"` | Plasma 6 services |
| `desktop-environment.gnome` | nixos | `…use == "gnome"` | GNOME/GDM services |
| `desktop-environment.cosmic` | nixos | `…use == "cosmic"` | COSMIC session and greeter |

### `home/default` — theming base

**Enable:** `cnix-visual.enable`

Turns on Stylix with `autoEnable = false` and an inline base16 scheme ("Dark Sun
Pro"), so targets only apply where they are explicitly wanted rather than
recolouring every application the moment the module is imported. It installs
`base16-schemes` and the Kvantum Qt style plugin, and disables Stylix's
`xresources` target, which otherwise produces stale-looking colours in X11-era
apps.

`useRecommendedFonts` installs Monaspace (Nerd Font), IBM Plex Sans/Mono, Be
Vietnam Pro, and Noto Color Emoji, enables fontconfig, and sets the Stylix
monospace and emoji fonts plus the terminal font size.
`cnix-visual.infra.fonts` is an alias of `stylix.fonts`, so font configuration
can be written under the facade's namespace.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-visual.enable` | `bool` | `false` | Enable the visual module. | Enables Stylix with the bundled base16 scheme and installs the theming packages. |
| `cnix-visual.useRecommendedFonts` | `bool` | `false` | Whether to use the recommended fonts for system and apps. | Installs Monaspace, IBM Plex, Be Vietnam Pro, and Noto Color Emoji, enables fontconfig, and sets the Stylix fonts and sizes. |
| `cnix-visual.useRecommendedTheme` | `bool` | `false` | Whether to use the recommended theme for system and apps. | Consumed by the desktop-environment modules to gate the recommended app theming. |
| `cnix-visual.infra.fonts` | *(alias of `stylix.fonts`)* | — | — | Writes through to `stylix.fonts`. |

### `home/desktop-environment` — DE base

**Enable:** `cnix-visual.desktop-environment.use`

Selects the desktop environment and applies what is common to both. For KDE it
installs the Plasma workspace and SDK packages, the glass window effect overlay,
sets the Plasma wallpaper and blur effect, and enables the effect in `kwinrc`;
for GNOME it enables dconf and sets the light and dark background URIs from the
wallpaper options.

With `useRecommendedTheme` it also aligns applications with the desktop: the
`one` colourscheme for nixvim with `termguicolors`, and Ghostty settings
(font family and size read from Stylix, an Atom One light/dark theme, and
`window-theme = "system"`) — which is what makes a terminal and editor match the
desktop rather than fighting it.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-visual.desktop-environment.use` | `enum [ "unset" "kde" "gnome" "cosmic" ]` | `"unset"` | The desktop environment to be managed. | Selects the DE branch; `unset` leaves desktop services unmanaged. |
| `…desktop-environment.wallpaper.light` | `nullOr path` | `null` | The wallpaper to be used in light mode. | Light-mode wallpaper for Plasma/GNOME. |
| `…desktop-environment.wallpaper.dark` | `nullOr path` | `null` | The wallpaper to be used in dark mode. | Dark-mode wallpaper, also fed to the KDE theme switcher. |

### `home/desktop-environment/gnome` — extensions

**Enable:** `desktop-environment.use == "gnome"` (with `cnix-visual.enable`)

Installs each configured extension package, enables its UUID in
`org/gnome/shell`, and writes its settings through `lib.cnix-visual.mkDconfTree`
at the extension's schema path. The module also assigns a recommended default set
(dash-to-dock, blur-my-shell, appindicators, user themes, gsconnect, kimpanel,
just-perfection, and more) with their settings — a plain list merge, so your own
entries extend rather than replace it.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `…gnome.extensions` | `listOf <submodule>` | `[ ]` | A list of GNOME extensions to be installed and configured. | Installs each extension and merges its settings into dconf. |
| `…gnome.extensions.*.package` | `package` | — | The package name of the GNOME extension to be installed. | Chooses the extension package, and from it the UUID and settings path. |
| `…gnome.extensions.*.settings` | `attrsOf anything` | `{ }` | A set of settings to be applied to the GNOME extension. | Written verbatim as dconf keys under the extension's schema. |

### `home/desktop-environment/kde` — theming and theme switcher

**Enable:** `desktop-environment.use == "kde"`

The largest module in the facade. It installs the KDE theming set — Klassy window
decorations, `cirius-visual-desktop-themes`, Candy/Tela icon themes, Inter, and
the panel widgets (`plasmusic-toolbar`, `plasma-audio-visualizer`, the FairyWren
app menu) — and applies them: `widgetStyle = "Klassy"`, matching window
decorations, and a `klassyrc` written from a TOML asset. With
`useRecommendedFonts` it sets the Plasma font roles (Inter, Monaspice for fixed
width).

`themeSwitcher.enable` adds the part that is hard to get right by hand: a
`kde-theme-switcher` script that applies a colour scheme, desktop theme, icon
theme, and wallpaper, plus a `kde-theme-watch` script and systemd timer that pick
light or dark by hour. The themes themselves default to the Klassy and
`cirius-visual` sets with `mkDefault`, so overriding one field does not mean
redeclaring the rest.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `…kde.themeSwitcher.enable` | `bool` | — | Enable the KDE theme switcher. | Installs the switcher and the watch timer plus autostart entry. |
| `…themeSwitcher.settings.mode` | `enum [ "interval" "scheduled" ]` | `"scheduled"` | The mode of the theme switcher, either 'interval' or 'scheduled'. | Chooses between interval-based and sunrise/sunset scheduling. |
| `…themeSwitcher.settings.intervalDuration` | `int` | `15` | The duration in minutes for the interval mode of the theme switcher. | Timer period when `mode = "interval"`. |
| `…themeSwitcher.settings.sunrise` | `int` | `7` | The hour of the day (0-23) when the light theme should be applied. | Hour at which the light theme takes over. |
| `…themeSwitcher.settings.sunset` | `int` | `16` | The hour of the day (0-23) when the dark theme should be applied. | Hour at which the dark theme takes over. |
| `…themeSwitcher.settings.themes.light` | `submodule` | `{ }` | The configuration for the light theme in KDE Plasma. | Light colour scheme/desktop theme/icon theme/wallpaper. |
| `…themes.light.color` | `str` | `"KlassyLight"` | The color scheme to be used in KDE Plasma configuration. | Applied via `plasma-apply-colorscheme`. |
| `…themes.light.plasma` | `str` | `"cirius-visual-light"` | The plasma theme to be used in KDE Plasma configuration. | Applied via `plasma-apply-desktoptheme`. |
| `…themes.light.icon` | `str` | `"Tela"` | The icon theme to be used in KDE Plasma configuration. | Applied via `plasma-changeicons`. |
| `…themes.light.wallpaper` | `nullOr path` | `null` | The wallpaper to be used in KDE Plasma configuration. | Applied via `plasma-apply-wallpaperimage`. |
| `…themeSwitcher.settings.themes.dark` | `submodule` | `{ }` | The configuration for the dark theme in KDE Plasma. | Dark colour scheme/desktop theme/icon theme/wallpaper. |
| `…themes.dark.color` | `str` | `"KlassyLight"` | The color scheme to be used in KDE Plasma configuration. | Dark-mode colour scheme. |
| `…themes.dark.plasma` | `str` | `"cirius-visual-light"` | The plasma theme to be used in KDE Plasma configuration. | Dark-mode desktop theme. |
| `…themes.dark.icon` | `str` | `"Tela"` | The icon theme to be used in KDE Plasma configuration. | Dark-mode icon theme. |
| `…themes.dark.wallpaper` | `nullOr path` | `null` | The wallpaper to be used in KDE Plasma configuration. | Dark-mode wallpaper. |
| `…kde.panelOnMonitors` | `listOf int` | `[ 0 ]` | List of monitor indices to be used in KDE Plasma configuration. | Which screens receive the generated panels. |
| `…kde.favoriteApps` | `listOf str` | `[ ]` | List of favorite applications to be shown in the KDE Plasma task manager. | Launchers in the icon-only task manager. |

### `home/desktop-environment/kde/panels` — panel layout

No options of its own. When the recommended theme is on and KDE is selected it
writes `programs.plasma.panels` for each monitor in `panelOnMonitors`: a top
panel with a pager, application title bar, app menu, and system monitors, and a
bottom panel with the launcher, task manager, audio visualiser, and system tray.
Sensor colours and the visualiser configuration come from TOML assets shipped
with the module.

### NixOS modules

The system side is thin, and gated only on `desktop-environment.use` — it does
not require `cnix-visual.enable`, because enabling a display manager and desktop
session is a system concern rather than a styling preference.

| Module | What it configures |
| --- | --- |
| `nixos/desktop-environment` | Declares `cnix-visual.desktop-environment.use` for the system class. |
| `nixos/desktop-environment/kde` | `services.desktopManager.plasma6.enable`, `services.displayManager.plasma-login-manager.enable`, `wl-clipboard`. |
| `nixos/desktop-environment/gnome` | `services.desktopManager.gnome.enable`, `services.displayManager.gdm.enable`, GNOME apps and developer tools with games disabled, `services.xserver` with a US layout. |
| `nixos/desktop-environment/cosmic` | `services.desktopManager.cosmic.enable`, `services.displayManager.cosmic-greeter.enable`. |

## Packages, overlays, and helpers

| Output | What it is |
| --- | --- |
| `pkgs.cnix-visual.cirius-visual-desktop-themes` | Light/dark Plasma desktop themes. |
| `pkgs.cnix-visual.klassy` | Klassy window decoration/application style plugin. |
| `pkgs.cnix-visual.fairy-wren` | FairyWren app-menu plasmoid. |
| `pkgs.cnix-visual.be-vietnam-pro` | Be Vietnam Pro font family (Google Fonts). |
| `kwin-effect-glass` overlay | Glass effect for KWin. |
| `kde-audio-vis` overlay | Plasma audio visualiser widget. |
| `lib.mkDconfTree` | Maps a nested attribute set to dconf keys under a base path. |

## Notes

- `desktop-environment.use` is declared twice, once per class — the home module
  drives user configuration, the NixOS module drives services. Keep their values
  aligned with the utils selector.
- The KDE, GNOME, and COSMIC system modules are gated on `use` only; the Stylix theming
  side needs `cnix-visual.enable` as well.
- `themeSwitcher.enable` declares no default, so it behaves as required once the
  option is referenced by the module's guards.
