{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      inherit (config.${namespace}.desktop-environment) use;
      enable = use == "kde";
    in
    lib.mkMerge [
      (lib.mkIf enable {
        environment = {
          plasma6.excludePackages = with pkgs.kdePackages; [ ];
          systemPackages = with pkgs; [ wl-clipboard ];
        };
        services = {
          desktopManager.plasma6.enable = true;
          displayManager.plasma-login-manager.enable = true;
        };
      })
    ];
}
