{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.sshd;
in
{
  options.${namespace}.sshd = {
    enable = lib.mkEnableOption "SSH server policy";
    ports = lib.mkOption {
      type = options.services.openssh.ports.type;
      default = [ 22 ];
      description = "TCP ports on which the SSH server listens.";
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open SSH ports on all interfaces. Otherwise declare interface-specific firewall access.";
    };
    settings = lib.mkOption {
      type = options.services.openssh.settings.type;
      default = { };
      description = "OpenSSH server settings. These override the facade's key-only authentication defaults.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = lib.mkDefault cfg.ports;
      openFirewall = lib.mkDefault cfg.openFirewall;
      settings = lib.mkMerge [
        {
          PermitRootLogin = lib.mkDefault "no";
          PasswordAuthentication = lib.mkDefault false;
          KbdInteractiveAuthentication = lib.mkDefault false;
          X11Forwarding = lib.mkDefault false;
        }
        # Forward user definitions, not the upstream submodule's evaluated defaults.
        # Otherwise PasswordAuthentication=true and LogLevel=INFO would override policy.
        (lib.mkAliasDefinitions options.${namespace}.sshd.settings)
      ];
    };
  };
}
