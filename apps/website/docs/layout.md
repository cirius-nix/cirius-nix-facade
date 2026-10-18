---
title: Layout
sidebar_position: 3
description: Directory conventions shared by every subflake, and what each one covers.
---

# Layout

## Repository

```
.
├── flakes/                    # one subflake per concern
│   ├── cirius-lib/            # shared library helpers (no modules)
│   ├── cirius-utils/
│   ├── cirius-security/
│   ├── cirius-dev/
│   ├── cirius-visual/
│   ├── cirius-networking/
│   ├── cirius-gaming/
│   ├── cirius-art/
│   ├── cirius-office/
│   ├── cirius-virt/
│   └── cirius-vn/
├── apps/
│   └── website/               # this site
├── devenv.nix                 # dev shell for working on this repo
├── devenv.yaml
└── Taskfile.yml
```

## Subflake

Each subflake follows the same [snowfall-lib](https://github.com/snowfallorg/lib)
conventions:

```
flakes/<name>/
├── flake.nix
├── modules/
│   ├── home/<module>/default.nix      # home-manager modules
│   ├── nixos/<module>/default.nix     # NixOS modules
│   ├── darwin/<module>/default.nix    # nix-darwin modules
│   └── <class>/default/default.nix    # aggregate: imports every sibling module
├── packages/<pkg>/default.nix         # packages exported by the flake
├── overlays/<overlay>/default.nix     # nixpkgs overlays
└── lib/default.nix                    # flake-local library helpers
```

The `<class>/default` aggregate is discovered automatically and imports every
sibling module, which is what makes a one-line opt-in possible.

## Flakes

| Flake | Namespace | Coverage |
| --- | --- | --- |
| `cirius-lib` | `cnix-lib` | Shared option builders (`mkStrOpt`, `mkBoolOpt`, `mkPackageOpt`, …) and `failWhen` assertion helpers. Consumed by other flakes as `inputs.cirius-lib.lib`. |
| `cirius-utils` | `cnix-utils` | Base home/nixos modules: package manager (flatpak), desktop shortcuts, power controls, chrome webapps, connectivity. |
| `cirius-security` | `cnix-sec` | Secret management via [sops-nix](https://github.com/Mic92/sops-nix): home + nixos secret/secure-store modules and SSH port management. |
| `cirius-dev` | `cnix-dev` | Dev tooling: nixvim, shell/term, git (gh, lazygit), AI agents (`llm-agents`, codex, deepseek), and toolchains (nix, go, nodejs, cpp, aws, android, unity, latex, markdown). |
| `cirius-visual` | `cnix-visual` | Desktop look & feel: stylix, plasma-manager, KDE/GNOME modules, custom KDE themes/packages, and kwin/audio-vis overlays. |
| `cirius-networking` | `cnix-net` | Networking modules and helpers. |
| `cirius-gaming` | `cnix-gaming` | Emulation/streaming via [eden](https://github.com/Daaboulex/eden-nix) and an eden overlay. |
| `cirius-art` | `cnix-art` | Creative tooling: `pen-cli`/`pen-desktop`, `comfy-desktop`, and sprite tooling. |
| `cirius-office` | `cnix-office` | Office modules. |
| `cirius-virt` | `cnix-virt` | Virtualisation: containers and virtual desktops. |
| `cirius-vn` | `cnix-vn` | Vietnamese input via [fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus). |
