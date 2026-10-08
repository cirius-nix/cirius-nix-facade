{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.chrome-webapps = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Chrome Web Apps.";
    };
    settings = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.chromium;
        description = "The package name of the Chrome browser to be used.";
      };
      workspaceDataPath = lib.mkOption {
        type = lib.types.path;
        description = "The path to the workspace data directory for Chrome Web Apps.";
      };
      workspaces = lib.mkOption {
        type =
          with lib.types;
          attrsOf (submodule {
            options = {
              apps = lib.mkOption {
                type =
                  with lib.types;
                  attrsOf (submodule {
                    options = {
                      url = lib.mkOption {
                        type = lib.types.str;
                        description = "The URL of the Chrome Web App.";
                      };
                      categories = lib.mkOption {
                        type = with lib.types; listOf str;
                        default = [ ];
                        description = "A list of categories for the Chrome Web App.";
                      };
                      genericName = lib.mkOption {
                        type = lib.types.str;
                        description = "A generic name for the Chrome Web App.";
                      };
                      comment = lib.mkOption {
                        type = lib.types.str;
                        description = "A description of the Chrome Web App.";
                      };
                      icon = lib.mkOption {
                        type = with lib.types; nullOr path;
                        default = null;
                        description = "The path to the icon for the Chrome Web App.";
                      };
                      className = lib.mkOption {
                        type = lib.types.str;
                        description = "The class name for the Chrome Web App.";
                      };
                    };
                  });
                default = { };
                description = "A set of Chrome Web Apps to be installed in the workspace.";
              };
            };
          });
        default = { };
        description = "A set of workspaces for Chrome Web Apps, it shared the user data directory with the main Chrome browser.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.chrome-webapps) enable settings;
      execCMD = lib.getExe settings.package;

      mkDesktopEntry = workspaceName: appName: app: {
        name = appName;
        inherit (app)
          categories
          genericName
          comment
          icon
          ;
        exec = lib.concatStringsSep " " [
          execCMD
          "--user-data-dir=${settings.workspaceDataPath}/${workspaceName}"
          "--app=${app.url}"
        ];
        terminal = false;
        settings.StartupWMClass = app.className;
      };

      mkWorkspaceEntries =
        workspaceName: workspace:
        lib.mapAttrs' (
          appName: app:
          lib.nameValuePair "${workspaceName}-${appName}" (mkDesktopEntry workspaceName appName app)
        ) workspace.apps;

      workspaceEntries = lib.mapAttrsToList mkWorkspaceEntries settings.workspaces;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [ settings.package ];
        xdg.desktopEntries = lib.mergeAttrsList workspaceEntries;
      })
    ];
}
