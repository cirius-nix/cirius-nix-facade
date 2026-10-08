{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment = {
    use = lib.mkOption {
      type = lib.types.enum [
        "unset"
        "kde"
        "gnome"
      ];
      default = "unset";
      description = "The desktop environment to be managed.";
    };
  };
}
