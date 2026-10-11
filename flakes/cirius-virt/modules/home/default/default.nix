{
  inputs,
  config,
  namespace,
  lib,
  ...
}:
{
  options.${namespace} =
    let
      cnix-lib = inputs.cirius-lib.lib;
    in
    {
      containerRegistry = cnix-lib.mkStrOpt {
        default = "docker.io";
        description = "The container registry to be used for unqualified image names.";
      };
    };
  config =
    let
      inherit (config.${namespace}) containerRegistry;
    in
    {
      xdg.configFile."containers/registries.conf".text = ''
        unqualified-search-registries = ["${containerRegistry}"]
      '';
    };
}
