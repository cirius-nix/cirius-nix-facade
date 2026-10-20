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
      ageSSHKeyPaths = lib.mkOption {
        type = lib.types.nullOr options.sops.age.sshKeyPaths.type;
        default = null;
        description = "SSH private key paths used as age identities. Null preserves upstream discovery; an empty list disables it.";
      };
      generateAgeKey = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Generate the age identity at ageKeyFile if it does not exist. Encrypt secrets for its public recipient separately.";
      };
      defaultSecretFormat = lib.mkOption {
        type = options.sops.defaultSopsFormat.type;
        default = "yaml";
        description = "Default format of encrypted secret files.";
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
        assertions = [
          {
            assertion = !config.sops.age.generateKey || config.sops.age.keyFile != null;
            message = "cnix-sec: generateAgeKey requires an age key file path.";
          }
        ];
        sops = {
          age = {
            keyFile = lib.mkIf (settings.ageKeyFile != null) (lib.mkDefault settings.ageKeyFile);
            sshKeyPaths = lib.mkIf (settings.ageSSHKeyPaths != null) settings.ageSSHKeyPaths;
            generateKey = lib.mkDefault settings.generateAgeKey;
          };
          defaultSopsFormat = lib.mkDefault settings.defaultSecretFormat;
          useTmpfs = lib.mkDefault true;
          useSystemdActivation = true;
          defaultSopsFile = lib.mkIf (settings.defaultSecretFile != null) (
            lib.mkDefault settings.defaultSecretFile
          );
        };
      })
    ];
}
