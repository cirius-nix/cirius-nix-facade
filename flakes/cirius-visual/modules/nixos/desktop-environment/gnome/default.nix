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
      enable = use == "gnome";
    in
    lib.mkMerge [
      (lib.mkIf enable {
        environment.systemPackages = with pkgs; [
          desktop-file-utils
          dconf-editor
        ];
        services = {
          desktopManager.gnome.enable = true;
          displayManager.gdm.enable = true;
          udev.packages = with pkgs; [ gnome-settings-daemon ];
          gnome = {
            core-apps.enable = true;
            core-developer-tools.enable = true;
            games.enable = false;
          };
          xserver = {
            enable = true;
            xkb = {
              layout = "us";
              variant = "";
            };
          };
        };
      })
    ];
}
