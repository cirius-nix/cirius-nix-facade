# Cirius Nix Facade

A personal [Nix](https://nixos.org/) configuration split into small, composable
subflakes — one per concern. There is no root `flake.nix`: this repository is a
**facade** whose subflakes are consumed individually by the actual host configs
(NixOS, nix-darwin, and home-manager).

Every subflake is built with
[snowfall-lib](https://github.com/snowfallorg/lib) `mkLib` / `mkFlake`, so
packages, modules, overlays, and library functions are discovered from a
conventional directory layout and exposed under a per-flake namespace (e.g.
`cnix-dev`).

## Layout

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
│   └── website/               # landing site + docs (Docusaurus)
├── devenv.nix                 # dev shell for working on this repo
├── devenv.yaml
└── Taskfile.yml
```

Each subflake follows the same snowfall-lib conventions:

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

## Flakes

| Flake | Namespace | Coverage |
| --- | --- | --- |
| `cirius-lib` | `cnix-lib` | Shared option builders (`mkStrOpt`, `mkBoolOpt`, `mkPackageOpt`, …) and `failWhen` assertion helpers. Consumed by other flakes as `inputs.cirius-lib.lib`. |
| `cirius-utils` | `cnix-utils` | Base home/nixos modules: package manager (flatpak), desktop shortcuts, power controls, chrome webapps, connectivity. |
| `cirius-security` | `cnix-sec` | Simple defaults for SOPS secrets, SSH clients/servers and tunnels, LUKS storage, firewall, and Fail2ban. Advanced settings use upstream options. |
| `cirius-dev` | `cnix-dev` | Dev tooling: nixvim, shell/term, git (gh, lazygit), AI agents (`llm-agents`, codex, deepseek), a self-hosted GitHub Actions runner, and toolchains (nix, go, nodejs, cpp, aws, android, unity, latex, markdown). |
| `cirius-visual` | `cnix-visual` | Desktop look & feel: stylix, plasma-manager, KDE/GNOME modules, custom KDE themes/packages, and kwin/audio-vis overlays. |
| `cirius-networking` | `cnix-net` | Local AdGuard Home DNS filtering, SSH/Caddy host routing, and optional Tailscale. |
| `cirius-gaming` | `cnix-gaming` | Emulation/streaming via [eden](https://github.com/Daaboulex/eden-nix) and an eden overlay. |
| `cirius-art` | `cnix-art` | Creative tooling: `openpencil-cli`/`openpencil-desktop`, `comfy-desktop`, and sprite tooling. |
| `cirius-office` | `cnix-office` | Office modules. |
| `cirius-virt` | `cnix-virt` | Virtualisation: containers and virtual desktops. |
| `cirius-vn` | `cnix-vn` | Vietnamese input via [fcitx5-lotus](https://github.com/LotusInputMethod/fcitx5-lotus). |

## Using a subflake

Reference a subflake directly by its directory with the `?dir=` query parameter.
For example, to pull in the dev flake:

```nix
{
  inputs.cirius-dev = {
    url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

A consuming config can then enable the namespaced options the modules expose, e.g.
`cnix-dev.git.enable = true;` or `cnix-sec.secret-mgt.enable = true;`.

The flakes also share code through `cirius-lib`:

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

## Development

The repository root is a [devenv](https://devenv.sh/) shell providing Nix tooling
and [go-task](https://taskfile.dev/). Enter it with:

```sh
devenv shell
```

Update every subflake's locked inputs at once:

```sh
task update-flakes
```

This walks each `flakes/*/` directory and runs `nix flake update` inside it.

The landing page and documentation live in `apps/website` (Docusaurus, pnpm) and
are published to GitHub Pages by the `deploy-website` workflow on every push to
`main` that touches them. See `apps/website/README.md` to run it locally.

## Adding a flake or module

1. Create `flakes/<name>/flake.nix` following the existing pattern: set a unique
   `namespace`, wire inputs (with `inputs.nixpkgs.follows = "nixpkgs"`), and call
   `core.mkFlake`.
2. Drop modules under `flakes/<name>/modules/<class>/<module>/default.nix`. A
   `modules/<class>/default/default.nix` aggregate is picked up automatically and
   imports every sibling module — useful for one-line opt-in.
3. Namespace your options and config under `options.${namespace}.<module>` so they
   don't collide with upstream options, and guard them behind an `enable` flag.
