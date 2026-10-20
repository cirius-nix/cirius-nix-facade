{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.firewall;
in
{
  options.${namespace}.firewall = {
    enable = lib.mkEnableOption "host firewall configuration";
    allowedTCPPorts = lib.mkOption {
      type = options.networking.firewall.allowedTCPPorts.type;
      default = [ ];
      description = "TCP ports accepted on every interface. Other modules can add ports.";
    };
    allowedUDPPorts = lib.mkOption {
      type = options.networking.firewall.allowedUDPPorts.type;
      default = [ ];
      description = "UDP ports accepted on every interface. Other modules can add ports.";
    };
    interfaces = lib.mkOption {
      type = options.networking.firewall.interfaces.type;
      default = { };
      description = "Interface-specific firewall rules, using the NixOS interface option type.";
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      inherit (cfg) allowedTCPPorts allowedUDPPorts interfaces;
    };
  };
}
