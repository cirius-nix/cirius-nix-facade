{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  config =
    let
      inherit (config.${namespace}) enable desktop-environment useRecommendedTheme;
      inherit (desktop-environment) use kde;
      panelOnMonitors = lib.unique (kde.panelOnMonitors);

      audioVisualizerWidget = {
        name = "org.muddyblack.plasmaAudioVisualizer";
        config = with builtins; fromTOML (readFile ../assets/audio-vis.config.toml);
      };
    in
    lib.mkMerge [
      (lib.mkIf (enable && use == "kde" && useRecommendedTheme) (
        let
          mkTopPanels = screen: [
            # left
            {
              location = "top"; # top | bottom | left | right | floating
              alignment = "center"; # left | center | right
              height = 32;
              floating = true;
              hiding = "none"; # none | autohide | windowscover | windowsbelow | dodgewindows | normalpanel | windowsgobelow
              inherit screen;
              lengthMode = "fill"; # fit | fill | custom
              offset = 0;
              opacity = "opaque"; # adaptive | opaque | translucent
              widgets = [
                "org.kde.plasma.pager"
                "org.kde.plasma.marginsseparator"
                {
                  name = "com.github.antroids.application-title-bar";
                  config = {
                    Appearance = {
                      overrideElementsMaximized = true;
                      widgetButtonsIconsTheme = "Breeze";
                      widgetElements = "windowIcon,windowTitle";
                      widgetFillWidth = true;
                      widgetToolTipMode = "MaximizedWindow";
                      windowTitleUndefined = "Cirius Nix v4";
                      windowTitleMaximumWidth = 300;
                      windowTitleFontBold = false;
                      widgetElementsMaximized = "windowCloseButton,windowMinimizeButton,windowMaximizeButton,windowIcon,windowTitle";
                    };
                    Behavior = {
                      widgetMouseAreaMiddleClickAction = "";
                      widgetMouseAreaWheelDownAction = "";
                      widgetMouseAreaWheelUpAction = "";
                    };
                  };
                }
                "org.kde.plasma.marginsseparator"
                "org.kde.plasma.panelspacer"
                "org.kde.plasma.appmenu"
                "org.kde.plasma.panelspacer"
                {
                  name = "org.kde.plasma.systemmonitor.cpucore";
                  config = {
                    CurrentPreset = "org.kde.plasma.systemmonitor";
                    Appearance = {
                      chartFace = "org.kde.ksysguard.barchart";
                      title = "Individual Core Usage";
                    };
                    SensorColors = {
                      "cpu/cpu.*/usage" = "61,174,233";
                      "cpu/cpu0/usage" = "61,174,233";
                      "cpu/cpu1/usage" = "61,110,233";
                      "cpu/cpu10/usage" = "217,233,61";
                      "cpu/cpu11/usage" = "153,233,61";
                      "cpu/cpu12/usage" = "88,233,61";
                      "cpu/cpu13/usage" = "61,233,98";
                      "cpu/cpu14/usage" = "61,233,163";
                      "cpu/cpu15/usage" = "61,233,227";
                      "cpu/cpu2/usage" = "77,61,233";
                      "cpu/cpu3/usage" = "141,61,233";
                      "cpu/cpu4/usage" = "206,61,233";
                      "cpu/cpu5/usage" = "233,61,196";
                      "cpu/cpu6/usage" = "233,61,131";
                      "cpu/cpu7/usage" = "233,61,67";
                      "cpu/cpu8/usage" = "233,120,61";
                      "cpu/cpu9/usage" = "233,184,61";
                    };
                    Sensors = {
                      highPrioritySensorIds = ''["cpu/cpu.*/usage"]'';
                      totalSensors = ''["cpu/all/usage"]'';
                    };
                  };
                }
                {
                  name = "org.kde.plasma.systemmonitor.memory";
                  config = {
                    CurrentPreset = "org.kde.plasma.systemmonitor";
                    Appearance = {
                      chartFace = "org.kde.ksysguard.linechart";
                      title = "Memory Usage";
                    };
                    Sensors = {
                      highPrioritySensorIds = ''["memory/swap/used","memory/physical/application"]'';
                      lowPrioritySensorIds = ''["memory/physical/total"]'';
                      totalSensors = ''["memory/physical/usedPercent"]'';
                    };
                    SensorColors = {
                      "memory/physical/application" = "233,208,61";
                      "memory/physical/used" = "61,174,233";
                      "memory/swap/used" = "170,255,255";
                    };
                  };
                }
                {
                  name = "org.kde.plasma.systemmonitor.net";
                  config = {
                    CurrentPreset = "org.kde.plasma.systemmonitor";
                    Appearance = {
                      chartFace = "org.kde.ksysguard.linechart";
                      title = "Network Speed";
                    };
                    SensorColors = {
                      "network/all/download" = "61,174,233";
                      "network/all/upload" = "233,120,61";
                    };
                    Sensors = {
                      highPrioritySensorIds = ''["network/all/download","network/all/upload"]'';
                    };
                  };
                }
                "org.kde.plasma.marginsseparator"
                "org.kde.plasma.marginsseparator"
                "org.kde.plasma.digitalclock"
              ];
            }
          ];

          mkBottomPanel = screen: [
            {
              location = "bottom"; # top | bottom | left | right | floating
              alignment = "center"; # left | center | right
              height = 40;
              floating = true;
              hiding = "none"; # none | autohide | windowscover | windowsbelow | dodgewindows | normalpanel | windowsgobelow
              inherit screen;
              lengthMode = "custom"; # fit | fill | custom
              maxLength = 1200;
              minLength = 1200;
              offset = 0;
              opacity = "opaque"; # adaptive | opaque | translucent
              widgets = [
                "org.kde.plasma.kickoff"
                "org.kde.plasma.showdesktop"
                # "FreshDoctor.FairyWren-App-Menu"
                audioVisualizerWidget
                # {
                #   name = "plasmusic-toolbar";
                #   config = {
                #     General = {
                #       fallbackToIconWhenArtNotAvailable = true;
                #       mediaProgressInPanel = true;
                #       panelControlsSizeRatio = 0.6;
                #       useAlbumCoverAsPanelIcon = true;
                #     };
                #   };
                # }
                "org.kde.plasma.panelspacer"
                {
                  name = "org.kde.plasma.icontasks";
                  config = {
                    General = {
                      launchers = map (app: "applications:${app}") kde.favoriteApps;
                    };
                  };
                }
                "org.kde.plasma.panelspacer"
                {
                  name = "org.kde.plasma.systemtray";
                  config = {
                    General = {
                      extraItems = [
                        "org.kde.plasma.devicenotifier"
                        "org.kde.plasma.cameraindicator"
                        "org.kde.plasma.keyboardlayout"
                        "org.kde.plasma.keyboardindicator"
                        "org.kde.plasma.battery"
                        "org.kde.plasma.manage-inputmethod"
                        "org.kde.plasma.diskquota"
                        "org.kde.plasma.clipboard"
                        "org.kde.plasma.mediacontroller"
                        "org.kde.plasma.notifications"
                        "org.kde.plasma.trash"
                        "org.kde.plasma.weather"
                        "org.kde.plasma.addons.katesessions"
                        "org.kde.plasma.volume"
                        "org.kde.plasma.networkmanagement"
                      ];
                      hiddenItems = [
                        "org.kde.plasma.devicenotifier"
                        "org.kde.plasma.cameraindicator"
                        "org.kde.plasma.keyboardlayout"
                        "org.kde.plasma.keyboardindicator"
                        "org.kde.plasma.battery"
                        "org.kde.plasma.manage-inputmethod"
                        "org.kde.plasma.diskquota"
                        "org.kde.plasma.clipboard"
                        "Fcitx"
                        "org.kde.plasma.mediacontroller"
                        "org.kde.plasma.notifications"
                        "org.kde.plasma.trash"
                        "org.kde.plasma.weather"
                        "zero-trust-client"
                        "org.kde.plasma.addons.katesessions"
                        "opensnitch-ui"
                        "trayid30671"
                      ];
                      knownItems = [
                        "org.kde.plasma.cameraindicator"
                        "org.kde.plasma.clipboard"
                        "org.kde.plasma.devicenotifier"
                        "org.kde.plasma.manage-inputmethod"
                        "org.kde.plasma.mediacontroller"
                        "org.kde.plasma.notifications"
                        "org.kde.kscreen"
                        "org.kde.plasma.battery"
                        "org.kde.plasma.brightness"
                        "org.kde.plasma.keyboardindicator"
                        "org.kde.plasma.keyboardlayout"
                        "org.kde.plasma.networkmanagement"
                        "org.kde.plasma.volume"
                        "org.kde.plasma.weather"
                      ];
                      shownItems = [
                        "org.kde.plasma.volume"
                        "org.kde.plasma.networkmanagement"
                        "org.kde.plasma.bluetooth"
                      ];
                    };
                  };
                }
              ];
            }
          ];
        in
        {
          programs.plasma = {
            panels = lib.concatMap (screen: (mkTopPanels screen) ++ (mkBottomPanel screen)) panelOnMonitors;
          };
        }
      ))
    ];
}
