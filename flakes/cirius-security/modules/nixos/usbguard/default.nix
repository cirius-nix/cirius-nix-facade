{
  config,
  lib,
  namespace,
  options,
  ...
}:
let
  cfg = config.${namespace}.usbguard;
in
{
  options.${namespace}.usbguard = {
    enable = lib.mkEnableOption "USB device authorization";
    rules = lib.mkOption {
      type = options.services.usbguard.rules.type;
      default = null;
      description = "Explicit USBGuard rules. Use rules or ruleFile, but not both.";
    };
    ruleFile = lib.mkOption {
      type = options.services.usbguard.ruleFile.type;
      default = null;
      description = "Path to an existing USBGuard policy file. Enroll input devices and security tokens before activation.";
    };
    IPCAllowedUsers = lib.mkOption {
      type = options.services.usbguard.IPCAllowedUsers.type;
      default = [ "root" ];
      description = "Users allowed to control USBGuard through its IPC interface.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          (cfg.rules != null && builtins.match "[[:space:]]*" cfg.rules == null && cfg.ruleFile == null)
          || (cfg.rules == null && cfg.ruleFile != null);
        message = "cnix-sec: USBGuard requires exactly one explicit non-empty rules value or ruleFile.";
      }
    ];
    services.usbguard = {
      enable = true;
      inherit (cfg) rules ruleFile IPCAllowedUsers;
    };
  };
}
