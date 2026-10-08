{
  config,
  namespace,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports =
    (with inputs; [ ]) ++ (builtins.attrValues (removeAttrs inputs.self.nixosModules [ "default" ]));
  options.${namespace} = {
    unlockKDEWalletByLUKS = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to unlock the wallet by LUKS.";
    };
  };

  config =
    let
      inherit (config.${namespace}) unlockKDEWalletByLUKS;
    in
    lib.mkMerge [
      (lib.mkIf unlockKDEWalletByLUKS {
        assertions = [
          {
            assertion = config.services.desktopManager.plasma6.enable;
            message = "Unlocking the wallet by LUKS requires Plasma 6 to be enabled.";
          }
        ];
        systemd.services.plasmalogin.serviceConfig.KeyringMode = "inherit";
        security.pam.services.plasmalogin-autologin.rules.auth = {
          systemd_loadkey = {
            order = 0;
            control = "optional";
            modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
          };
          plasmalogin = {
            order = 1;
            control = "include";
            modulePath = "plasmalogin";
          };
        };
      })
    ];
}
