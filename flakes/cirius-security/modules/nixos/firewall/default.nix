{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.firewall.enable = lib.mkEnableOption "NixOS host firewall";
  config = lib.mkIf config.${namespace}.firewall.enable {
    networking.firewall.enable = true;
  };
}
