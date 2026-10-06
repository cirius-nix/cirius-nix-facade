# Taste

- Manages a personal dotfiles/NixOS configuration as a Nix flake (repo `~/.personal/dotfiles/cirius-nix-facade`), composing NixOS, home-manager, sops-nix (for secrets), and devenv (for dev shells) modules. Confidence: 0.6
- Debugs Nix evaluation errors with `nix repl`, loading flakes via the `:lf <path>` command and evaluating attributes directly (e.g. `outputs.nixosConfigurations.<host>.config`) rather than full builds. Confidence: 0.55
- Expects full traces when diagnosing Nix errors, running with `--show-trace`. Confidence: 0.5
