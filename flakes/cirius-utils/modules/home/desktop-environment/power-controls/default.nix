{
  config,
  namespace,
  lib,
  ...
}:
{

  options.${namespace}.desktop-environment.power-controls = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable recommended power controls for the system for KDE or GNOME.
      '';
    };
    settings = {
      onAC = {
        offDisplayTimeout = lib.mkOption {
          type = lib.types.int;
          default = 600;
          description = "The time in seconds before the display turns off when on AC power.";
        };
        sleep = {
          action = lib.mkOption {
            type = lib.types.enum [
              "sleep"
              "hibernate"
              "nothing"
              "shutdown"
            ];
            default = "sleep";
            description = "The action to take when the system is idle on AC power.";
          };
          timeout = lib.mkOption {
            type = lib.types.int;
            default = 1800;
            description = "The time in seconds before the system goes to sleep when on AC power.";
          };
        };
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.settings) managedDesktopEnvironment;
      inherit (config.${namespace}.desktop-environment.power-controls)
        enable
        settings
        ;
    in
    lib.mkMerge [
      (lib.mkIf (enable && managedDesktopEnvironment == "kde") {
        programs.plasma = {
          powerdevil = {
            AC = {
              autoSuspend = {
                action = settings.onAC.sleep.action; # hibernate | nothing | shutdown | sleep
                idleTimeout = settings.onAC.sleep.timeout;
              };
              turnOffDisplay = {
                idleTimeout = settings.onAC.offDisplayTimeout;
                idleTimeoutWhenLocked = "whenLockedAndUnlocked";
              };
            };
          };
        };
      })
    ];
}
