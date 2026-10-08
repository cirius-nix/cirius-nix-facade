{
  description = "Cirius Nix Facade";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake modules
    cirius-security = {
      url = "path:./flakes/cirius-security";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    cirius-art = {
      url = "path:./flakes/cirius-art";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    cirius-dev = {
      url = "path:./flakes/cirius-dev";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-facade";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./core/.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Facade";
          };
        };
      };
    in
    core.mkFlake {
      channels-config = {
        allowUnfree = true;
      };

      homes.modules = with inputs; [
        cirius-dev.homeModules.default
        cirius-security.homeModules.default
        cirius-art.homeModules.default
      ];

      systems.nixos.modules = with inputs; [
      ];
    };
}
