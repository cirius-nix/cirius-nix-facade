{
  config,
  inputs,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports =
    (with inputs; [
      nixvim.homeModules.default
      nix-index-database.homeModules.default
      codex-desktop-linux.homeManagerModules.default
      deepseek-harness.homeModules.default
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);

  options.${namespace} = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use recommended packages for nvim.";
    };
  };

  config =
    let
      inherit (config.${namespace}) shell useRecommendedPackages;
    in
    lib.mkMerge [
      (lib.mkIf useRecommendedPackages {
        home.packages = with pkgs; [
          bruno
          btop
          comma
          python3
          se-adopt
          artifact-plane
        ];
        programs.fastfetch = {
          enable = true;
        };
        programs.fish.interactiveShellInit = lib.mkIf (shell == "fish") ''
          ${lib.getExe pkgs.fastfetch}
        '';
        programs.eza = {
          enable = true;
          package = pkgs.eza;
          enableFishIntegration = shell == "fish";
          colors = "always";
          icons = "always";
        };
        programs.fzf = {
          enable = true;
          package = pkgs.fzf;
          enableFishIntegration = shell == "fish";
          historyWidget.fish = lib.mkIf (shell == "fish") { command = ""; };
        };
        programs.direnv = {
          enable = true;
          config = {
            global = {
              hide_env_diff = true;
            };
          };
        };
        programs.devenv = {
          enable = true;
          package = inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv;
        };
        programs.starship = {
          enable = true;
          enableFishIntegration = shell == "fish";
          enableTransience = true;
          enableInteractive = true;
        };
        programs.zoxide = {
          enable = true;
          enableFishIntegration = shell == "fish";
        };
      })
    ];
}
