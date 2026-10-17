{
  description = "Cirius Nix Networking";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cirius-lib = {
      url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-net";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Networking";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        systems.modules = {
          nixos = with inputs; [
          ];
          darwin = with inputs; [
          ];
        };

        homes.modules = with inputs; [
        ];
      };
    in
    outputs;
}
