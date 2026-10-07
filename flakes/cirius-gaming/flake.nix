{
  description = "Cirius Nix Gaming";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # architecture-specific overlays
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    eden = {
      url = "github:Daaboulex/eden-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-gaming";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Gaming";
          };
        };
      };
    in
    core.mkFlake {
      channels-config = {
        allowUnfree = true;
      };
      systems.modules.nixos = with inputs; [
        eden.nixosModules.default
      ];
    };
}
