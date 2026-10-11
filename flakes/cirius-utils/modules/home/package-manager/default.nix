{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule
      [ namespace "package-manager" "flatpak" "enable" ]
      [ "services" "flatpak" "enable" ]
    )
  ];
  options.${namespace}.package-manager =
    let
      cnix-lib = inputs.cirius-lib.lib;
      remotePackageType = lib.types.submodule (
        { name, ... }@args:
        {
          options.location = cnix-lib.mkStrOpt {
            description = "The URL of the remote repository.";
          };
          options.packages = cnix-lib.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "A list of package IDs to be installed from the remote repository.";
          };
          options.builtPackages = cnix-lib.mkListOpt {
            ofType = with lib.types; attrsOf str;
            readOnly = true;
            description = "A list of package IDs to be built from the remote repository.";
          };
          config.builtPackages = map (appId: {
            inherit appId;
            origin = name;
          }) args.config.packages;
        }
      );
    in
    {
      flatpak = {
        remotePackages = cnix-lib.mkAttrsOpt {
          ofType = remotePackageType;
          default = { };
          description = "A set of remote repositories and their packages to be installed.";
        };
      };
    };

  config =
    let
      inherit (config.${namespace}.package-manager) flatpak;
      remotes = lib.mapAttrsToList (name: value: {
        inherit name;
        inherit (value) location;
      }) flatpak.remotePackages;

      packages = lib.concatMap (remote: remote.builtPackages) (lib.attrValues flatpak.remotePackages);
    in
    lib.mkMerge [
      (lib.mkIf flatpak.enable {
        home.packages = [ pkgs.flatpak ];
        services.flatpak = {
          inherit remotes packages;
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
          overrides.settings = {
            global = {
              Context.sockets = [
                "wayland"
                "!x11"
                "!fallback-x11"
              ];
              Environment.XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
            };
          };
        };
      })

      # register default options
      (lib.mkIf flatpak.enable {
        ${namespace}.package-manager.flatpak.remotePackages.flathub = {
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
          packages = [ ];
        };
      })
    ];
}
