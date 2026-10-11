{
  description = "Cirius Nix Vietnam";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # input method
    fcitx5-lotus = {
      url = "github:LotusInputMethod/fcitx5-lotus";
    };

    cirius-lib = {
      url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      namespace = "cnix-vn";
      core = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
        snowfall = {
          inherit namespace;
          meta = {
            name = namespace;
            title = "Cirius Nix Vietnam";
          };
        };
      };

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
        };

        systems.modules.nixos = with inputs; [
          fcitx5-lotus.nixosModules.fcitx5-lotus
        ];
      };
    in
    outputs;
}
