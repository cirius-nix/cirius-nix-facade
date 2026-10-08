{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [
        namespace
        "package-manager"
        "flatpak"
        "packages"
      ]
      [
        "services"
        "flatpak"
        "packages"
      ]
    )
    (lib.mkAliasOptionModule
      [
        namespace
        "package-manager"
        "flatpak"
        "settings"
        "remotes"
      ]
      [
        "services"
        "flatpak"
        "remotes"
      ]
    )
  ];
  options.${namespace}.package-manager = {
    flatpak = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Flatpak support.";
      };
      settings = { };
    };
  };

  config =
    let
      inherit (config.${namespace}.package-manager) flatpak;
    in
    lib.mkMerge [
      (lib.mkIf flatpak.enable {
        services.flatpak = {
          enable = true;
          remotes = [
            {
              name = "flathub-beta";
              location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
            }
          ];
        };
      })
    ];
}
