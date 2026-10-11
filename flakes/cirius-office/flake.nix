{
  description = "Cirius Nix Office";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cirius-utils = {
      url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-office";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Office";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        home.modules = with inputs; [
          nix-flatpak.homeManagerModules.nix-flatpak
          cirius-utils.homeModules.default
        ];
      };
    in
    outputs;
}
