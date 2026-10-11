{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment =
    let
      cnix-lib = inputs.cirius-lib.lib;
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
