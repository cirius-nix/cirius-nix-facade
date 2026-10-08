{
  namespace,
  lib,
  config,
  ...
}:
{
  # alias sops
  imports = [
    (lib.mkAliasOptionModule
      [
        namespace
        "secret-mgt"
        "placeholder"
      ]
      [ "sops" "placeholder" ]
    )
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
      description = "Enable secret management.";
    };
    settings = {
      ageKeyFile = lib.mkOption {
        type = lib.types.str;
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
      inherit (config.${namespace}) secret-mgt;
      inherit (secret-mgt) settings;
    in
    lib.mkMerge [
      (lib.mkIf secret-mgt.enable {
        sops = {
          age.keyFile = lib.mkForce settings.ageKeyFile;
          defaultSopsFormat = lib.mkDefault "yaml";
          defaultSopsFile = lib.mkDefault settings.defaultSecretFile;
        };
      })
    ];
}
