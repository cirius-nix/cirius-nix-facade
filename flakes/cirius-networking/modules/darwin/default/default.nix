{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace};
  caddyfile = pkgs.writeText "Caddyfile" (
    ''
      {
        default_bind 127.0.0.1
        skip_install_trust
      }
    ''
    + lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: upstream: ''
        ${name} {
          tls internal
          reverse_proxy ${upstream}
        }
      '') cfg.routes
    )
  );
in
{
  options.${namespace} = {
    enable = lib.mkEnableOption "local Caddy reverse proxies";
    routes = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "penpot.home.arpa" = "127.0.0.1:9001";
      };
      description = "Local HTTPS names mapped to published ports on the Mac. Set up local DNS and trust the Caddy CA separately.";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.caddy ];
    environment.etc."cirius/Caddyfile".source = caddyfile;
    system.activationScripts.postActivation.text = ''
      install -d -m 0700 /var/lib/cirius-caddy
    '';
    launchd.daemons.cirius-caddy = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.caddy}/bin/caddy"
          "run"
          "--config"
          "${caddyfile}"
          "--adapter"
          "caddyfile"
        ];
        EnvironmentVariables = {
          HOME = "/var/lib/cirius-caddy";
          XDG_DATA_HOME = "/var/lib/cirius-caddy/data";
          XDG_CONFIG_HOME = "/var/lib/cirius-caddy/config";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/cirius-caddy.log";
        StandardErrorPath = "/var/log/cirius-caddy.log";
      };
    };
  };
}
