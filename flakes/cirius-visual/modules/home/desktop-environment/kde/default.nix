{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.desktop-environment.kde = {
    themeSwitcher = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = false;
        description = "Whether to enable the KDE theme switcher script.";
      };
      settings =
        let
          themeConfigModule = lib.types.submodule {
            options.color = lib.mkOption {
              type = with lib.types; str;
              default = "KlassyLight";
              description = "The color scheme to be used in KDE Plasma configuration.";
            };
            options.plasma = lib.mkOption {
              type = with lib.types; str;
              default = "cirius-visual-light";
              description = "The plasma theme to be used in KDE Plasma configuration.";
            };
            options.icon = lib.mkOption {
              type = with lib.types; str;
              default = "candy-icons";
              description = "The icon theme to be used in KDE Plasma configuration.";
            };
            options.wallpaper = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = "The wallpaper to be used in KDE Plasma configuration.";
            };
          };
        in
        {
          mode = lib.mkOption {
            type = lib.types.enum [
              "interval"
              "scheduled"
            ];
            default = "scheduled";
          };
          intervalDuration = lib.mkOption {
            type = with lib.types; int;
            default = 15;
            description = "The duration in minutes for the interval mode of the theme switcher.";
          };
          sunrise = lib.mkOption {
            type = with lib.types; int;
            default = 7;
            description = "The hour of the day (0-23) when the light theme should be applied.";
          };
          sunset = lib.mkOption {
            type = with lib.types; int;
            default = 16;
            description = "The hour of the day (0-23) when the dark theme should be applied.";
          };
          themes = {
            light = lib.mkOption {
              type = themeConfigModule;
              default = { };
              description = "The configuration for the light theme in KDE Plasma.";
            };
            dark = lib.mkOption {
              type = themeConfigModule;
              default = { };
              description = "The configuration for the dark theme in KDE Plasma.";
            };
          };
        };
    };
    panelOnMonitors = lib.mkOption {
      type = with lib.types; listOf int;
      default = [ 0 ];
      description = "List of monitor names to be used in KDE Plasma configuration.";
    };
    favoriteApps = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "List of favorite applications to be shown in the KDE Plasma task manager.";
    };
  };
  config =
    let
      inherit (config.${namespace})
        enable
        desktop-environment
        useRecommendedFonts
        useRecommendedTheme
        ;
      inherit (desktop-environment) use kde;
      inherit (kde) themeSwitcher;
    in
    lib.mkMerge [
      (lib.mkIf (enable && use == "kde" && useRecommendedTheme) ({
        home.packages =
          with pkgs;
          with pkgs.${namespace};
          [
            plasmusic-toolbar
            plasma-audio-visualizer
            fairy-wren
            cirius-visual-desktop-themes
            candy-icons
            tela-icon-theme
            inter
          ]
          ++ [ pkgs.${namespace}.klassy ];

        programs.plasma = {
          workspace = {
            widgetStyle = "Klassy";
            windowDecorations = {
              library = "org.kde.klassy";
              theme = "Klassy";
            };
          };
          configFile."klassy/klassyrc" = with builtins; fromTOML (readFile ./assets/klassyrc.toml);
        };
      }))

      (lib.mkIf (enable && use == "kde" && useRecommendedFonts) {
        home.packages = with pkgs; [
          inter
        ];
        programs.plasma.fonts = {
          general = {
            family = "Inter";
            pointSize = 10;
          };
          menu = {
            family = "Inter";
            pointSize = 10;
          };
          toolbar = {
            family = "Inter";
            pointSize = 10;
          };
          small = {
            family = "Inter";
            pointSize = 9;
          };
          windowTitle = {
            family = "Inter";
            pointSize = 10;
          };
          fixedWidth = {
            family = "MonaspiceKr Nerd Font Mono";
            pointSize = 10;
          };
        };
      })
      (lib.mkIf (enable && use == "kde" && useRecommendedTheme && themeSwitcher.enable) (
        let
          inherit (themeSwitcher.settings) themes;
          workspacePkg = pkgs.kdePackages.plasma-workspace;
          wallpaperPkg = pkgs.kdePackages.plasma-workspace-wallpapers;

          themeSwitcherPkg = pkgs.writeShellApplication {
            name = "kde-theme-switcher";
            text = ''
              case "''${1:-}" in
                light)
                  color="${themes.light.color}"
                  plasma="${themes.light.plasma}"
                  icon="${themes.light.icon}"
                  wallpaper="${themes.light.wallpaper}"
                  ;;
                dark)
                  color="${themes.dark.color}"
                  plasma="${themes.dark.plasma}"
                  icon="${themes.dark.icon}"
                  wallpaper="${themes.dark.wallpaper}"
                  ;;
                *)
                  echo "Usage: kde-theme-switch {light|dark}" >&2
                  exit 1
                  ;;
              esac

              ${workspacePkg}/bin/plasma-apply-colorscheme "$color"
              ${workspacePkg}/bin/plasma-apply-desktoptheme "$plasma"
              ${workspacePkg}/libexec/plasma-changeicons "$icon"
              ${workspacePkg}/bin/plasma-apply-wallpaperimage "$wallpaper"
            '';
          };

          themeWatch = pkgs.writeShellScript "kde-theme-watch" ''
            hour=$(${pkgs.coreutils}/bin/date +%H)

            if (( 10#$hour >= ${toString themeSwitcher.settings.sunrise} && 10#$hour < ${toString themeSwitcher.settings.sunset})); then
              mode=light
            else
              mode=dark
            fi

            ${themeSwitcherPkg}/bin/kde-theme-switcher "$mode"
          '';
        in
        {
          ${namespace}.desktop-environment.kde.themeSwitcher.settings.themes = {
            light = lib.mkDefault {
              color = "KlassyLight";
              plasma = "cirius-visual-light";
              icon = "Tela";
              wallpaper =
                if desktop-environment.wallpaper.light != null then
                  desktop-environment.wallpaper.light
                else
                  "${wallpaperPkg}/share/wallpapers/Sub-Arctic/contents/images/5120x2880.png";
            };
            dark = lib.mkDefault {
              color = "KlassyDark";
              plasma = "cirius-visual-dark";
              icon = "Tela";
              wallpaper =
                if desktop-environment.wallpaper.dark != null then
                  desktop-environment.wallpaper.dark
                else
                  "${wallpaperPkg}/share/wallpapers/Sub-Arctic/contents/images_dark/5120x2880.png";
            };
          };
          home.packages = with pkgs; [
            themeSwitcherPkg
          ];
          systemd.user.services."kde-theme-watch" = {
            Unit = {
              Description = "KDE Theme Watcher Service";
              After = [ "graphical-session.target" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = themeWatch;
            };
          };

          systemd.user.timers."kde-theme-watch" = {
            Unit.Description = "KDE Theme Watcher Timer";
            Timer = {
              OnCalendar =
                if themeSwitcher.settings.mode == "interval" then
                  "*:0/${toString themeSwitcher.settings.intervalDuration}"
                else
                  [
                    "*-*-* ${toString themeSwitcher.settings.sunrise}:00"
                    "*-*-* ${toString themeSwitcher.settings.sunset}:00"
                  ];
              Persistent = true;
              Unit = "kde-theme-watch.service";
            };
            Install = {
              WantedBy = [ "timers.target" ];
            };
          };

          xdg.configFile."autostart/kde-theme-watch.desktop" = {
            text = ''
              [Desktop Entry]
              Type=Application
              Name=KDE Theme Watcher
              Exec=${pkgs.systemd}/bin/systemctl --user start kde-theme-watch.service
              OnlyShowIn=KDE;
              Terminal=false
              X-KDE-autostart-phase=2
            '';
          };
        }
      ))
    ];
}
