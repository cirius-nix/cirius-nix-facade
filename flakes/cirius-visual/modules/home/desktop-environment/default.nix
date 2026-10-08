{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment = {
    use = lib.mkOption {
      type = lib.types.enum [
        "unset"
        "kde"
        "gnome"
      ];
      default = "unset";
      description = "The desktop environment to be managed.";
    };
    useRecommendedTheme = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to use recommended themes for the selected desktop environment.
        This will apply a consistent theme across applications and the desktop
        environment itself.
      '';
    };
    wallpaper = {
      light = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "The wallpaper to be used in light mode.";
      };
      dark = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "The wallpaper to be used in dark mode.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) enable desktop-environment;
      inherit (desktop-environment) useRecommendedTheme;
    in
    lib.mkMerge [
      (lib.mkIf (enable && desktop-environment.use == "kde") {
        programs.plasma = {
          enable = true;
          workspace.wallpaper = desktop-environment.wallpaper.light;
        };
      })

      (lib.mkIf (enable && desktop-environment.use == "gnome") {
        dconf = {
          enable = true;
          settings = {
            "org/gnome/desktop/background" = {
              picture-uri = lib.mkIf (
                desktop-environment.wallpaper.light != null
              ) "file://${lib.toString desktop-environment.wallpaper.light}";

              picture-uri-dark = lib.mkIf (
                desktop-environment.wallpaper.dark != null
              ) "file://${lib.toString desktop-environment.wallpaper.dark}";
            };
          };
        };
      })

      # apply recommended theme for applications
      (lib.mkIf (enable && useRecommendedTheme) {
        programs = {
          nixvim = {
            colorschemes.one.enable = true;
            colorscheme = "one";
            opts.termguicolors = true;
          };
          ghostty.settings = {
            theme = "Atom One Dark";
            minimum-contrast = 1;
          };
        };
      })
    ];
}
