{
  config,
  options,
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
        type = options.sops.age.keyFile.type;
        default = null;
        description = "The age key used for encrypting secrets.";
      };
      defaultSecretFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
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
        sops = {
          age.keyFile = lib.mkIf (settings.ageKeyFile != null) (lib.mkDefault settings.ageKeyFile);
          defaultSopsFormat = lib.mkDefault "yaml";
          useTmpfs = lib.mkDefault true;
          useSystemdActivation = true;
          defaultSopsFile = lib.mkIf (settings.defaultSecretFile != null) (
            lib.mkDefault settings.defaultSecretFile
          );
        };
      })
    ];
}
