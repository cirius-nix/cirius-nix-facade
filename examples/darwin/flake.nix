{
  description = "Apple Silicon example consuming the facade subflakes";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cirius-dev = {
      url = "path:../../flakes/cirius-dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cirius-security = {
      url = "path:../../flakes/cirius-security";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cirius-utils = {
      url = "path:../../flakes/cirius-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cirius-virt = {
      url = "path:../../flakes/cirius-virt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cirius-networking = {
      url = "path:../../flakes/cirius-networking";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ darwin, home-manager, ... }:
    {
      darwinConfigurations.mac = darwin.lib.darwinSystem {
        modules = [
          home-manager.darwinModules.home-manager
          inputs.cirius-networking.darwinModules.default
          {
            nixpkgs.hostPlatform = "aarch64-darwin";
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ inputs.cirius-dev.overlays.default ];
            home-manager.useGlobalPkgs = true;
            system.stateVersion = 6;
            system.primaryUser = "cirius"; # Change to your existing macOS username.
            users.users.cirius.home = "/Users/cirius";
            programs.fish.enable = true;
            cnix-net = {
              enable = true;
              routes = {
                "doop.home.arpa" = "127.0.0.1:4400";
                "penpot.home.arpa" = "127.0.0.1:9001";
                "container.home.arpa" = "127.0.0.1:2000";
              };
            };
            home-manager.users.cirius = { ... }: {
              imports = [
                inputs.cirius-dev.homeModules.darwin
                inputs.cirius-security.homeModules.default
                inputs.cirius-utils.homeModules.darwin
                inputs.cirius-virt.homeModules.darwin
              ];
              home.stateVersion = "26.05";
              cnix-dev = {
                shell = "fish";
                useRecommendedPackages = true;
                git.enable = true;
                editor.nvim.enable = true;
                editor.code.enable = true;
                toolchain = {
                  nix.enable = true;
                  go.enable = true;
                  nodejs.enable = true;
                  markdown.enable = true;
                };
                ai.useClients = [
                  "claude"
                  "codex"
                  "opencode"
                  "kimi"
                ];
              };
              cnix-sec.ssh.enable = true;
              cnix-virt.container = {
                enable = true;
                containers = {
                  doop = {
                    enable = true;
                    publicUri = "https://doop.home.arpa";
                  };
                  penpot = {
                    enable = true;
                    publicUri = "https://penpot.home.arpa";
                  };
                  dockhand.enable = true;
                };
              };
            };
          }
        ];
      };
    };
}
