{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.apparmor;
in
{
  options.${namespace}.apparmor = {
    enable = lib.mkEnableOption "AppArmor application confinement";
    policies = lib.mkOption {
      type = options.security.apparmor.policies.type;
      default = { };
      description = "AppArmor policies, each with a disable, complain, or enforce state. Only applications with a loaded policy are covered.";
    };
    packages = lib.mkOption {
      type = options.security.apparmor.packages.type;
      default = [ ];
      description = "Packages that supply AppArmor includes. Includes do not automatically confine applications.";
    };
  };
  config = lib.mkIf cfg.enable {
    security.apparmor = {
      enable = true;
      inherit (cfg) policies packages;
    };
  };
}
