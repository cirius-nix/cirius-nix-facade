{
  config,
  namespace,
  lib,
  ...
}:
{
  config = lib.mkIf (config.${namespace}.desktop-environment.use == "cosmic") {
    services = {
      desktopManager.cosmic.enable = true;
      displayManager.cosmic-greeter.enable = true;
    };
  };
}
