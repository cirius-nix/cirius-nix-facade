let
  inherit (builtins) genList listToAttrs;

  mkAction = group: action: { inherit group action; };
  kwin = mkAction "kwin";
  plasmaShell = mkAction "plasmashell";
  powerDevil = mkAction "org_kde_powerdevil";
  spectacle = mkAction "services/org.kde.spectacle.desktop";
in
{
  "capture.screen-recording-ui" = spectacle "RecordScreen";
  "capture.screenshot" = spectacle "FullScreenScreenShot";
  "capture.screenshot-ui" = spectacle "OpenWithoutScreenshot";
  "capture.screenshot-window" = spectacle "ActiveWindowScreenShot";

  "desktop.application-view" = plasmaShell "activate application launcher";
  "desktop.overview" = kwin "Overview";
  "desktop.run-dialog" = mkAction "services/org.kde.krunner.desktop" "_launch";
  "desktop.shift-overview-down" = kwin "Cycle Overview Opposite";
  "desktop.shift-overview-up" = kwin "Cycle Overview";
  "desktop.show" = kwin "Show Desktop";

  "display.brightness-down" = powerDevil "Decrease Screen Brightness";
  "display.brightness-down-monitor" = powerDevil "Decrease Screen Brightness Small";
  "display.brightness-up" = powerDevil "Increase Screen Brightness";
  "display.brightness-up-monitor" = powerDevil "Increase Screen Brightness Small";

  "input.switch-source" = mkAction "KDE Keyboard Layout Switcher" "Switch to Next Keyboard Layout";
  "input.switch-source-back" =
    mkAction "KDE Keyboard Layout Switcher" "Switch to Last-Used Keyboard Layout";

  "mgt.switch-apps" = kwin "Walk Through Windows";
  "mgt.switch-apps-back" = kwin "Walk Through Windows (Reverse)";
  "mgt.switch-group" = kwin "Walk Through Windows of Current Application";
  "mgt.switch-group-back" = kwin "Walk Through Windows of Current Application (Reverse)";
  "mgt.switch-panels" = plasmaShell "cycle-panels";
  "mgt.switch-ws-down" = kwin "Switch One Desktop Down";
  "mgt.switch-ws-last" = kwin "Switch to Previous Desktop";
  "mgt.switch-ws-left" = kwin "Switch One Desktop to the Left";
  "mgt.switch-ws-right" = kwin "Switch One Desktop to the Right";
  "mgt.switch-ws-up" = kwin "Switch One Desktop Up";

  "win.activate-menu" = kwin "Window Operations Menu";
  "win.begin-move" = kwin "Window Move";
  "win.begin-resize" = kwin "Window Resize";
  "win.close" = kwin "Window Close";
  "win.lower" = kwin "Window Lower";
  "win.maximize" = kwin "Window Maximize";
  "win.maximize-horizontally" = kwin "Window Maximize Horizontal";
  "win.maximize-vertically" = kwin "Window Maximize Vertical";
  "win.minimize" = kwin "Window Minimize";
  "win.raise" = kwin "Window Raise";
  "win.raise-or-lower" = kwin "Toggle Window Raise/Lower";
  "win.to-center" = kwin "Window Move Center";
  "win.to-corner-ne" = kwin "Window Quick Tile Top Right";
  "win.to-corner-nw" = kwin "Window Quick Tile Top Left";
  "win.to-corner-se" = kwin "Window Quick Tile Bottom Right";
  "win.to-corner-sw" = kwin "Window Quick Tile Bottom Left";
  "win.to-mon-down" = kwin "Window One Screen Down";
  "win.to-mon-left" = kwin "Window One Screen to the Left";
  "win.to-mon-right" = kwin "Window One Screen to the Right";
  "win.to-mon-up" = kwin "Window One Screen Up";
  "win.to-side-e" = kwin "Window Quick Tile Right";
  "win.to-side-n" = kwin "Window Quick Tile Top";
  "win.to-side-s" = kwin "Window Quick Tile Bottom";
  "win.to-side-w" = kwin "Window Quick Tile Left";
  "win.to-ws-down" = kwin "Window One Desktop Down";
  "win.to-ws-left" = kwin "Window One Desktop to the Left";
  "win.to-ws-right" = kwin "Window One Desktop to the Right";
  "win.to-ws-up" = kwin "Window One Desktop Up";
  "win.toggle-above" = kwin "Window Above Other Windows";
  "win.toggle-fullscreen" = kwin "Window Fullscreen";
  "win.toggle-on-all-workspaces" = kwin "Window On All Desktops";
  "win.unmaximize" = kwin "Window Restore";
}
// (listToAttrs (
  genList (index: {
    name = "mgt.switch-to-app-${toString (index + 1)}";
    value = plasmaShell "activate task manager entry ${toString (index + 1)}";
  }) 9
))
// (listToAttrs (
  genList (index: {
    name = "win.move-to-ws-${toString (index + 1)}";
    value = kwin "Window to Desktop ${toString (index + 1)}";
  }) 11
))
// (listToAttrs (
  genList (index: {
    name = "mgt.switch-to-ws-${toString (index + 1)}";
    value = kwin "Switch to Desktop ${toString (index + 1)}";
  }) 11
))
