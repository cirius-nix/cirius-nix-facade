{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.sshd.enable = lib.mkEnableOption "SSH server with NixOS defaults";
  config = lib.mkIf config.${namespace}.sshd.enable {
    services.openssh.enable = true;
  };
}
