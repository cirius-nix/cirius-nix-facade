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
        type = lib.types.str;
        default = null;
        description = "The age key used for encrypting secrets.";
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
          age.keyFile = lib.mkForce settings.ageKeyFile;
          defaultSopsFormat = lib.mkDefault "yaml";
        };
      })
    ];
}
