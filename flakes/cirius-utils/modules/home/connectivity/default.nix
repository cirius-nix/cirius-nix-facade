{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.connectivity = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable connectivity configuration.";
    };
    settings = {
      fileSync = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable file synchronization.";
        };
        settings = {
          port = lib.mkOption {
            type = lib.types.int;
            default = 8384;
            description = "Port for the file synchronization service.";
          };
          devices = lib.mkOption {
            type = lib.types.json;
            default = { };
            description = ''
              A set of devices to be used by syncthing. 
              Each device should have an id attribute.
            '';
          };
          folders = lib.mkOption {
            type = lib.types.json;
            default = { };
            description = ''
              A set of folders to be synced by syncthing. 
              Each folder should have an id attribute and a devices attribute which is a list of device ids.'';
          };
          credentials = {
            username = lib.mkOption {
              type = lib.types.str;
              default = "admin";
              description = "Username for the file synchronization service.";
            };
            passwordFile = lib.mkOption {
              type = with lib.types; nullOr path;
              default = null;
              description = "Path to the password file for the file synchronization service.";
            };
          };
        };
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.connectivity) enable settings;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs.kdePackages; [ kdeconnect-kde ];
      })

      (lib.mkIf (enable && settings.fileSync.enable) (
        let
          fileSyncSettings = settings.fileSync.settings;
        in
        {
          services.syncthing = {
            enable = true;
            guiAddress = "http://127.0.0.1:${toString fileSyncSettings.port}";
            guiCredentials = {
              inherit (fileSyncSettings.credentials) username passwordFile;
            };
            settings = {
              gui.theme = lib.mkDefault "black";
              inherit (fileSyncSettings) devices folders;
            };
          };
        }
      ))
    ];
}
