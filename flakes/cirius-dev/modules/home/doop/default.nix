{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.doop;
in
{
  options.${namespace}.doop = {
    enable = lib.mkEnableOption "Doop Desktop";
    package = lib.mkPackageOption pkgs "Doop Desktop" {
      default = [
        namespace
        "doop"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/doop" = [ "doop.desktop" ];
    };
  };
}
