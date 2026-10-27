{
  description = "Cirius Nix Dev";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # snowfall utilities
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixvim module
    nixvim = {
      url = "github:nix-community/nixvim";
    };

    # ai-agents
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deepseek-harness = {
      url = "github:moraxyc/deepseek-harness.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # software-engineering principal
    software-engineering = {
      url = "github:hieutran21198/software-engineering?ref=plane-v1.28.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # desktop
    devenv = {
      url = "github:cachix/devenv";
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

      outputs = core.mkFlake {
        channels-config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };

        homes.modules = with inputs; [
          nixvim.homeModules.nixvim
          codex-desktop-linux.homeManagerModules.default
          nix-index-database.homeModules.default
          deepseek-harness.homeModules.default
        ];

        nixos.modules = with inputs; [
          nix-index-database.nixosModules.default
        ];
      };
    in
    outputs;
}
