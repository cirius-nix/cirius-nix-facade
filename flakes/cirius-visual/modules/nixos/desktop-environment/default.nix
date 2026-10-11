{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment =
    let
      inherit (lib) cnix-lib;
    in
    {
      use = cnix-lib.mkEnumOpt {
        values = [
          "unset"
          "kde"
          "gnome"
        ];
        default = "unset";
        description = "The desktop environment to be managed.";
      };
    };
}
