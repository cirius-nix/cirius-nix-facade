{
  inputs,
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports =
    (with inputs; [
      sops-nix.homeManagerModules.sops
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);

  options.${namespace} = {
    ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable SSH configuration.";
      };

      additionalConfigPaths = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional SSH configuration files to include.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) ssh;
    in
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          sops
          age
        ];
      }

      (lib.mkIf ssh.enable {
        services.ssh-agent = {
          enable = true;
          defaultMaximumIdentityLifetime = lib.mkDefault 28800;
        };

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            AddKeysToAgent = "yes";
          };
          extraConfig = lib.concatMapStringsSep "\n" (x: "Include ${x}") ssh.additionalConfigPaths;
        };
      })
    ];
}
