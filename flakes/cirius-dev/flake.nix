{
  description = "Cirius Nix Dev";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

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

    # nixvim module
    nixvim = {
      url = "github:nix-community/nixvim";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-dev";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Dev";
          };
        };
      };
    in
    core.mkFlake {
      channels-config = {
        allowUnfree = true;
      };

      homes.modules = with inputs; [
        nixvim.homeModules.nixvim
      ];
    };
}
