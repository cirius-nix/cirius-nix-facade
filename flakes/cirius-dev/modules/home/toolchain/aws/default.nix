{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.aws = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable AWS CLI and related tools.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.aws) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          awscli2
          terraform
          terragrunt
          aws-vault
          chamber
        ];
      })
    ];
}
