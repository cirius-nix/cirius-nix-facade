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

        home.modules = with inputs; [ ];
      };
    in
    outputs;
}
