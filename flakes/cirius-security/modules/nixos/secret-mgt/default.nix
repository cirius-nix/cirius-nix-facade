{
  config,
  namespace,
  lib,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [
        namespace
        "secret-mgt"
        "secrets"
      ]
      [ "sops" "secrets" ]
    )
    (lib.mkAliasOptionModule
      [
        namespace
        "secret-mgt"
        "templates"
      ]
      [ "sops" "templates" ]
    )
  ];
  options.${namespace}.secret-mgt = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable secret management";
    };
    settings = {
      ageKeyFile = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "The age key used for encrypting secrets.";
      };
      defaultSecretFile = lib.mkOption {
        type = lib.types.path;
        default = null;
        description = "The default secret file to be used for secret management.";
      };
    };
  };
  config =
    let
      inherit (config.${namespace}.secret-mgt) enable settings;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        assertions = [
          {
            assertion = settings.ageKeyFile != null;
            message = "The age key file must be specified when secret management is enabled.";
          }
        ];
        sops = {
          age.keyFile = lib.mkForce settings.ageKeyFile;
          defaultSopsFormat = lib.mkDefault "yaml";
          useTmpfs = lib.mkDefault true;
          useSystemdActivation = true;
          defaultSopsFile = settings.defaultSecretFile;
        };
      })
    ];
}
