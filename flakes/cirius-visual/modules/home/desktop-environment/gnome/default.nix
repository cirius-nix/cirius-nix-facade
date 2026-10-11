{
  config,
  namespace,
  pkgs,
  lib,
  ...
}:
{
  options.${namespace}.desktop-environment.gnome = {
    extensions = lib.mkOption {
      type =
        with lib.types;
        listOf (submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.package;
              description = "The package name of the GNOME extension to be installed.";
            };
            settings = lib.mkOption {
              type = with lib.types; attrsOf anything;
              default = { };
              description = "A set of settings to be applied to the GNOME extension.";
            };
          };
        });
      default = [ ];
      description = "A list of GNOME extensions to be installed and configured.";
    };
  };

  config =
    let
      inherit (config.${namespace}) enable desktop-environment useRecommendedTheme;
      inherit (desktop-environment) use gnome;

      extensionSettings = lib.foldl' lib.recursiveUpdate { } (
        map (
          {
            package,
            settings ? { },
            ...
          }:
          lib.${namespace}.mkDconfTree "org/gnome/shell/extensions/${package.extensionPortalSlug}" settings
        ) gnome.extensions
      );
    in
    lib.mkMerge [
      (lib.mkIf (enable && use == "gnome") {
        home.packages = map (x: x.package) gnome.extensions;
        dconf = {
          enable = true;
          settings = {
            # background
            "org/gnome/desktop/background" = {
              picture-uri = lib.mkIf (
                desktop-environment.wallpaper.light != null
              ) "file://${lib.toString desktop-environment.wallpaper.light}";

              picture-uri-dark = lib.mkIf (
                desktop-environment.wallpaper.dark != null
              ) "file://${lib.toString desktop-environment.wallpaper.dark}";
            };

            # extensions
            "org/gnome/shell" = {
              enabled-extensions = map (x: x.package.extensionUuid) gnome.extensions;
            };
          }
          // extensionSettings;
        };
      })

      # fill default extensions
      (lib.mkIf (enable && use == "gnome") {
        ${namespace}.desktop-environment.gnome.extensions = [
          { package = pkgs.gnomeExtensions.appindicator; }
          { package = pkgs.gnomeExtensions.user-themes; }
          { package = pkgs.gnomeExtensions.dynamic-music-pill; }
          { package = pkgs.gnomeExtensions.gsconnect; }
          { package = pkgs.gnomeExtensions.places-status-indicator; }
          { package = pkgs.gnomeExtensions.screentospace; }
          { package = pkgs.gnomeExtensions.kimpanel; }
          {
            package = pkgs.gnomeExtensions.dash-to-dock;
            settings = {
              "/" = {
                dock-position = gnome.profile-default.dockPosition;
              };
            };
          }
          {
            package = pkgs.gnomeExtensions.just-perfection;
            settings = {
              "/" = {
                startup-status = 0;
              };
            };
          }
          {
            package = pkgs.gnomeExtensions.runcat;
            settings = {
              "/" = {
                custom-system-monitor-enabled = false;
                displaying-items = "character-and-percentage";
                idle-threshold = 10;
                invert-speed = false;
              };
            };
          }
          {
            package = pkgs.gnomeExtensions.caffeine;
            settings = {
              "/" = {
                cli-toggle = false;
                duration-timer = 2;
                duration-timer-list = [
                  900
                  1800
                  3600
                ];
                enable-fullscreen = true;
                enable-mpris = true;
                indicator-position-max = 2;
                nightlight-control = "never";
                restore-state = false;
                screen-blank = "never";
                show-indicator = "always";
                show-notifications = true;
                show-timer = true;
                show-toggle = true;
                trigger-apps-mode = "on-running";
              };
            };
          }
          {
            package = pkgs.gnomeExtensions.blur-my-shell;
            settings = {
              "/" = {
                rounded-blur-found = false;
                settings-version = 2;
                pipelines = "{'pipeline_default': {'name': <'Default'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000000'>, 'params': <{'radius': <30>, 'brightness': <0.59999999999999998>}>}>]>}, 'pipeline_default_rounded': {'name': <'Default rounded'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000001'>, 'params': <{'radius': <30>, 'brightness': <0.59999999999999998>, 'unscaled_radius': <30>}>}>, <{'type': <'corner'>, 'id': <'effect_000000000002'>, 'params': <{'radius': <12>}>}>]>}}";
              };
              dash-to-dock = {
                blur = true;
                static-blur = true;
                style-dash-to-dock = 0;
                brightness = 0.6;
                sigma = 30;
              };
              panel = {
                static-blur = true;
                pipeline = "pipeline_default_rounded";
                corner-radius = 0;
                brightness = 0.6;
                sigma = 30;
              };
              appfolder = {
                brightness = 0.6;
                sigma = 30;
              };
              window-list = {
                brightness = 0.6;
                sigma = 30;
              };
              applications = {
                blacklist = [ ];
                brightness = 0.6;
                sigma = 30;
                blur = true;
                enable-all = true;
                opacity = 215;
                static-blur = true;
                pipeline = "pipeline_default_rounded";
              };
            };
          }
        ];
      })
    ];
}
