{
  description = "Cirius Nix Visual";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # core
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kwin-effects-glass = {
      url = "github:4v3ngR/kwin-effects-glass";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kde-audio-vis = {
      url = "github:Muddyblack/audio-wave-visualizer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cnix-lib = {
      url = "github:cirius-nix/cirius-nix-facade/tree/main/flakes/cirius-lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-visual";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Visual";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        systems.nixos.modules = with inputs; [
          stylix.nixosModules.stylix
        ];

        home.modules = with inputs; [
          plasma-manager.homeModules.plasma-manager
          stylix.homeModules.stylix
        ];
      };
    in
    outputs;
}
