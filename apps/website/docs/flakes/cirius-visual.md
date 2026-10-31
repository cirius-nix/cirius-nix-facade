---
title: cirius-visual
sidebar_position: 4
description: Desktop-environment styling — Stylix theming, fonts, KDE Plasma and GNOME configuration, panels, and a light/dark theme switcher.
---

# cirius-visual

The desktop layer. Stylix provides the colour scheme and fonts, and the
desktop-environment modules turn that into an actual KDE Plasma or GNOME
configuration — including panels, window decorations, and a scheduled light/dark
theme switcher that follows sunrise and sunset rather than a fixed hour.

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

`desktop-environment.use` is also declared by the NixOS module of the same name,
so setting it once covers both the user and system sides.

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
| `cnix-visual.desktop-environment.use` | `enum [ "unset" "kde" "gnome" ]` | `"unset"` | The desktop environment to be managed. | Selects the DE branch; `unset` leaves the visual modules idle. |
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
  drives user configuration, the NixOS module drives services. Set it once in
  your configuration and both react.
- The KDE and GNOME system modules are gated on `use` only; the Stylix theming
  side needs `cnix-visual.enable` as well.
- `themeSwitcher.enable` declares no default, so it behaves as required once the
  option is referenced by the module's guards.
