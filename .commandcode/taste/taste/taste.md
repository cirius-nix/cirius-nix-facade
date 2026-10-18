# Taste
- Manages a personal dotfiles/NixOS configuration as a Nix flake (repo `~/.personal/dotfiles/cirius-nix-facade`), composing NixOS, home-manager, sops-nix (for secrets), and devenv (for dev shells) modules. Confidence: 0.6
- Structures the config as a facade flake with per-concern subflakes under `flakes/<name>/` (e.g. `cirius-security`) wired together, with modules generated/discovered by snowfall-lib's `mkFlake` from `modules/{home,nixos,darwin}/<name>/default.nix`. Confidence: 0.55
- Debugs Nix evaluation errors with `nix repl`, loading flakes via the `:lf <path>` command and evaluating attributes directly (e.g. `outputs.nixosConfigurations.<host>.config`) rather than full builds. Confidence: 0.55
- Expects full traces when diagnosing Nix errors, running with `--show-trace`. Confidence: 0.5
- Prefers fixing root causes permanently in the Nix config (flake wrapper/env changes, then rebuild) over one-off manual workarounds that leave the underlying problem in place. Confidence: 0.4
- Places site/app projects under an `apps/<name>/` directory in the repo (monorepo convention) rather than at the repo root. Confidence: 0.55
- Hosts static sites on GitHub Pages and auto-deploys them via GitHub Actions on push. Confidence: 0.6
- Prefers the latest version of a framework/tool (e.g. asked for Docusaurus "latest"). Confidence: 0.5
