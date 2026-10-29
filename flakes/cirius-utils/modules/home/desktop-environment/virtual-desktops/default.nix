{
  config,
  namespace,
  lib,
  ...
}:
{
  options.${namespace}.desktop-environment.virtual-desktops = {
    rows = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "The number of rows in the virtual desktops.";
    };
    number = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "The number of virtual desktops.";
    };
  };

  config =
    let
      inherit (config.${namespace}.desktop-environment.virtual-desktops) rows number;
      inherit (config.${namespace}) managedDesktopEnvironment;
    in
    lib.mkMerge [
      (lib.mkIf (managedDesktopEnvironment == "kde") {
        programs.plasma = {
          virtualDesktops = {
            inherit rows number;
          };
        };
      })

      (lib.mkIf (managedDesktopEnvironment == "gnome") {
        dconf.settings = {
          "org/gnome/desktop/wm/preferences" = {
            num-workspaces = number;
          };

          "org/gnome/mutter" = {
            dynamic-workspaces = false;
          };
        };
      })
    ];
}
