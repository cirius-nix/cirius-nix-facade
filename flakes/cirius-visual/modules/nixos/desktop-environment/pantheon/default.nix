{
  config,
  namespace,
  lib,
  ...
}:
{
  config = lib.mkIf (config.${namespace}.desktop-environment.use == "pantheon") {
    services = {
      desktopManager.pantheon.enable = true;
      xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
      };
    };
  };
}
