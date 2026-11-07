{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.family-media;
  libraryOption = lib.mkOption {
    type = with lib.types; listOf path;
    default = [ ];
    description = ''
      Existing library directories exposed read-only to the service. Add these
      paths in the application's library UI after creating its administrator.
      Use dedicated mounts outside /home and /mnt, which are hidden from services.
    '';
  };
  protectLibraries = paths: {
    unitConfig.RequiresMountsFor = paths;
    serviceConfig = {
      BindReadOnlyPaths = paths;
      ProtectHome = true;
      # The host may expose selected directories at /srv; do not let the
      # service bypass those read-only views via the original disk mount.
      InaccessiblePaths = [ "-/mnt" ];
      ProtectSystem = lib.mkForce "strict";
    };
  };
in
{
  options.${namespace}.family-media = {
    enable = lib.mkEnableOption "private Jellyfin and Immich services";
    jellyfin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Jellyfin when family-media is enabled.";
      };
      libraryPaths = libraryOption;
    };
    immich = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Immich when family-media is enabled.";
      };
      libraryPaths = libraryOption;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = map (path: {
          assertion =
            lib.hasPrefix "/" path
            && !(lib.hasPrefix "/mnt/" path)
            && path != "/mnt"
            && !(lib.hasPrefix "/home/" path)
            && path != "/home";
          message = "family-media libraryPaths must be absolute paths outside /mnt and /home; use read-only /srv bind mounts.";
        }) (cfg.jellyfin.libraryPaths ++ cfg.immich.libraryPaths);
      }
      (lib.mkIf cfg.jellyfin.enable {
        services.jellyfin = {
          enable = true;
          openFirewall = false;
        };
        systemd.services.jellyfin = lib.mkMerge [
          (protectLibraries cfg.jellyfin.libraryPaths)
          {
            # Run before upstream preStart, which can exit early when an encoding
            # config is unchanged. Preserve unrelated XML and fail on bad input.
            preStart = lib.mkBefore ''
              ${lib.getExe pkgs.python3} ${./private-network.py} ${lib.escapeShellArg "${config.services.jellyfin.configDir}/network.xml"}
            '';
            serviceConfig.ReadWritePaths = [
              config.services.jellyfin.dataDir
              config.services.jellyfin.configDir
              config.services.jellyfin.cacheDir
              config.services.jellyfin.logDir
            ];
          }
        ];
      })
      (lib.mkIf cfg.immich.enable {
        services.immich = {
          enable = true;
          host = "127.0.0.1";
          openFirewall = false;
          # Native PostgreSQL and Redis use Unix sockets. Keep uploads and
          # application state on POSIX storage, separate from external libraries.
          mediaLocation = lib.mkDefault "/var/lib/immich";
        };
        systemd.services.immich-server = lib.mkMerge [
          (protectLibraries cfg.immich.libraryPaths)
          {
            unitConfig.RequiresMountsFor = [ config.services.immich.mediaLocation ];
            serviceConfig.ReadWritePaths = [ config.services.immich.mediaLocation ];
          }
        ];
      })
    ]
  );
}
