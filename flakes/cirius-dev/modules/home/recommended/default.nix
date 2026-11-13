{
  config,
  inputs,
  namespace,
  lib,
  pkgs,
  ...
}:
{
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
        home.packages =
          with pkgs;
          [
            btop
            comma
            python3
            go-task
            curl
            gnutar
            postgresql
            se-adopt
            artifact-plane
            ttyd
            prek
            lychee
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.bruno ];
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
          package =
            if pkgs.stdenv.hostPlatform.isDarwin then
              pkgs.devenv
            else
              inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv;
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
