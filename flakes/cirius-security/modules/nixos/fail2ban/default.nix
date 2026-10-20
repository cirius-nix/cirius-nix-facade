{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.fail2ban;
in
{
  options.${namespace}.fail2ban = {
    enable = lib.mkEnableOption "Fail2ban intrusion prevention";
    settings = {
      bantime = lib.mkOption {
        type = options.services.fail2ban.bantime.type;
        default = "10m";
        description = "Duration of an address ban.";
      };
      maxretry = lib.mkOption {
        type = options.services.fail2ban.maxretry.type;
        default = 3;
        description = "Number of failed attempts before a ban.";
      };
      ignoreIP = lib.mkOption {
        type = options.services.fail2ban.ignoreIP.type;
        default = [ ];
        description = "Additional addresses or networks exempt from bans.";
      };
    };
    jails = lib.mkOption {
      type = options.services.fail2ban.jails.type;
      default = { };
      description = "Fail2ban jails and filters, using the NixOS jail option type.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.firewall.enable || config.networking.nftables.enable;
        message = "cnix-sec: Fail2ban requires a firewall. Enable networking.firewall or networking.nftables.";
      }
    ];
    services.fail2ban = {
      enable = true;
      bantime = lib.mkDefault cfg.settings.bantime;
      maxretry = lib.mkDefault cfg.settings.maxretry;
      ignoreIP = cfg.settings.ignoreIP;
      jails = cfg.jails;
    };
  };
}
