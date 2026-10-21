{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.fail2ban.enable =
    lib.mkEnableOption "Fail2ban with its NixOS defaults and a firewall";
  config = lib.mkIf config.${namespace}.fail2ban.enable {
    services.fail2ban.enable = true;
    networking.firewall.enable = lib.mkDefault true;
  };
}
