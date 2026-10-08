{
  description = "Cirius Nix Utils";

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

    # flatpak apps
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs =
    inputs:
    let
      namespace = "cnix-utils";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Utils";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        home.modules = with inputs; [
          nix-flatpak.homeManagerModules.nix-flatpak
        ];
      };
    in
    outputs;
}
