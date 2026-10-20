{
  description = "Cirius Nix Security";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used by module checks; consumers do not need to import it.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-sec";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Security";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        systems.modules = {
          nixos = with inputs; [
            sops-nix.nixosModules.sops
          ];
          darwin = with inputs; [
            sops-nix.darwinModules.sops
          ];
        };

        homes.modules = with inputs; [
          sops-nix.homeModules.sops
        ];
      };
    in
    outputs
    // {
      checks = inputs.nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        import ./tests {
          inherit inputs system;
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        }
      );
    };
}
