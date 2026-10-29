{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment.screen-edges = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable recommended screen edge settings for the system for KDE or GNOME.
      '';
    };
  };

  config =
    let
      inherit (config.${namespace}.settings) managedDesktopEnvironment;
      inherit (config.${namespace}.desktop-environment.screen-edges) enable;
    in
    lib.mkMerge [
      (lib.mkIf (enable && managedDesktopEnvironment == "kde") {
        programs.plasma.configFile.kwinrc = {
          Effect-windowview = {
            BorderActivateAll = 7;
            BorderActivate = 1;
          };
          Effect-overview.BorderActivate = 9;
          ElectricBorders.BottomLeft = "KRunner";
          Windows = {
            ElectricBorderMaximize = true;
            ElectricBorderTiling = true;
            ElectricBorderCornerRatio = 0.25;
            ElectricBorders = 1;
            ElectricBorderDelay = 75;
            ElectricBorderCooldown = 350;
          };
          ScreenEdges = {
            RemainActiveOnFullscreen = false;
          };
          EdgeBarrier = {
            CornerBarrier = true;
            EdgeBarrier = 100;
          };
        };
      })

      (lib.mkIf (enable && managedDesktopEnvironment == "gnome") {
        home.packages = [
          pkgs.gnomeExtensions.custom-hot-corners-extended
        ];

        dconf.settings = {
          "org/gnome/shell" = {
            enabled-extensions = [
              "custom-hot-corners-extended@G-dH.github.com"
            ];
          };

          "org/gnome/desktop/interface" = {
            enable-hot-corners = false;
          };
        };
      })
    ];
}
