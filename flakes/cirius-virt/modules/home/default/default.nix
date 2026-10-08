{
  config,
  namespace,
  lib,
  ...
}:
{
  options.${namespace} = {
    containerRegistry = lib.mkOption {
      type = lib.types.str;
      default = "docker.io";
      description = "The default container registry to be used for unqualified image names.";
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
