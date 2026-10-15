{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment =
    let
      cnix-lib = inputs.cirius-lib.lib;
    in
    {
      use = cnix-lib.mkEnumOpt {
        values = [
          "unset"
          "kde"
          "gnome"
        ];
        default = "unset";
        description = "The desktop environment to be managed.";
      };
      wallpaper = {
        light = cnix-lib.mkPathOpt {
          default = null;
          nullable = true;
          description = "The wallpaper to be used in light mode.";
        };
        dark = cnix-lib.mkPathOpt {
          default = null;
          nullable = true;
          description = "The wallpaper to be used in dark mode.";
        };
      };
    };

  config =
    let
      inherit (config.${namespace}) enable desktop-environment useRecommendedTheme;
    in
    lib.mkMerge [
      (lib.mkIf (enable && desktop-environment.use == "kde") {
        home.packages =
          with pkgs;
          with pkgs.kdePackages;
          [
            plasma-workspace
            plasma-sdk
            ksvg
            kwin-effects-glass
          ];
        programs.plasma = {
          enable = true;
          workspace.wallpaper = desktop-environment.wallpaper.light;
          kwin.effects.blur = {
            enable = false;
            strength = 10;
            noiseStrength = 7;
          };
          configFile.kwinrc = {
            Plugins.glassEnabled = true;
          };
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
            font-family = config.stylix.fonts.monospace.name;
            font-size = config.stylix.fonts.sizes.terminal;
            theme = "light:Atom One Light,dark:Atom One Dark";
            minimum-contrast = 1;
            window-theme = "system";
          };
        };
      })
    ];
}
