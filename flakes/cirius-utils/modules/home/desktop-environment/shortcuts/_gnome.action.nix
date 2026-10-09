let
  inherit (builtins) genList listToAttrs;
in
{
  "capture.screen-recording-ui" = "shell.show-screen-recording-ui";
  "capture.screenshot" = "shell.screenshot";
  "capture.screenshot-ui" = "shell.show-screenshot-ui";
  "capture.screenshot-window" = "shell.screenshot-window";

  "desktop.application-view" = "shell.toggle-application-view";
  "desktop.message-tray" = "shell.toggle-message-tray";
  "desktop.overview" = "shell.toggle-overview";
  "desktop.quick-settings" = "shell.toggle-quick-settings";
  "desktop.run-dialog" = "wm.panel-run-dialog";
  "desktop.shift-overview-down" = "shell.shift-overview-down";
  "desktop.shift-overview-up" = "shell.shift-overview-up";
  "desktop.show" = "wm.show-desktop";

  "display.brightness-cycle" = "shell.screen-brightness-cycle";
  "display.brightness-cycle-monitor" = "shell.screen-brightness-cycle-monitor";
  "display.brightness-down" = "shell.screen-brightness-down";
  "display.brightness-down-monitor" = "shell.screen-brightness-down-monitor";
  "display.brightness-up" = "shell.screen-brightness-up";
  "display.brightness-up-monitor" = "shell.screen-brightness-up-monitor";

  "input.switch-source" = "wm.switch-input-source";
  "input.switch-source-back" = "wm.switch-input-source-backward";

  "mgt.cycle-group" = "wm.cycle-group";
  "mgt.cycle-group-back" = "wm.cycle-group-backward";
  "mgt.cycle-panels" = "wm.cycle-panels";
  "mgt.cycle-panels-back" = "wm.cycle-panels-backward";
  "mgt.cycle-windows" = "wm.cycle-windows";
  "mgt.cycle-windows-back" = "wm.cycle-windows-backward";
  "mgt.switch-apps" = "wm.switch-applications";
  "mgt.switch-apps-back" = "wm.switch-applications-backward";
  "mgt.switch-group" = "wm.switch-group";
  "mgt.switch-group-back" = "wm.switch-group-backward";
  "mgt.switch-panels" = "wm.switch-panels";
  "mgt.switch-panels-back" = "wm.switch-panels-backward";
  "mgt.switch-windows" = "wm.switch-windows";
  "mgt.switch-windows-back" = "wm.switch-windows-backward";
  "mgt.switch-ws-down" = "wm.switch-to-workspace-down";
  "mgt.switch-ws-last" = "wm.switch-to-workspace-last";
  "mgt.switch-ws-left" = "wm.switch-to-workspace-left";
  "mgt.switch-ws-right" = "wm.switch-to-workspace-right";
  "mgt.switch-ws-up" = "wm.switch-to-workspace-up";

  "win.activate-menu" = "wm.activate-window-menu";
  "win.always-on-top" = "wm.always-on-top";
  "win.begin-move" = "wm.begin-move";
  "win.begin-resize" = "wm.begin-resize";
  "win.close" = "wm.close";
  "win.lower" = "wm.lower";
  "win.maximize" = "wm.maximize";
  "win.maximize-horizontally" = "wm.maximize-horizontally";
  "win.maximize-vertically" = "wm.maximize-vertically";
  "win.minimize" = "wm.minimize";
  "win.raise" = "wm.raise";
  "win.raise-or-lower" = "wm.raise-or-lower";
  "win.set-spew-mark" = "wm.set-spew-mark";
  "win.to-center" = "wm.move-to-center";
  "win.to-corner-ne" = "wm.move-to-corner-ne";
  "win.to-corner-nw" = "wm.move-to-corner-nw";
  "win.to-corner-se" = "wm.move-to-corner-se";
  "win.to-corner-sw" = "wm.move-to-corner-sw";
  "win.to-mon-down" = "wm.move-to-monitor-down";
  "win.to-mon-left" = "wm.move-to-monitor-left";
  "win.to-mon-right" = "wm.move-to-monitor-right";
  "win.to-mon-up" = "wm.move-to-monitor-up";
  "win.to-side-e" = "wm.move-to-side-e";
  "win.to-side-n" = "wm.move-to-side-n";
  "win.to-side-s" = "wm.move-to-side-s";
  "win.to-side-w" = "wm.move-to-side-w";
  "win.to-ws-down" = "wm.move-to-workspace-down";
  "win.to-ws-left" = "wm.move-to-workspace-left";
  "win.to-ws-right" = "wm.move-to-workspace-right";
  "win.to-ws-up" = "wm.move-to-workspace-up";
  "win.toggle-above" = "wm.toggle-above";
  "win.toggle-fullscreen" = "wm.toggle-fullscreen";
  "win.toggle-maximize" = "wm.toggle-maximize";
  "win.toggle-on-all-workspaces" = "wm.toggle-on-all-workspaces";
  "win.unmaximize" = "wm.unmaximize";
}
// (listToAttrs (
  genList (index: {
    name = "mgt.open-new-win-${toString (index + 1)}";
    value = "shell.open-new-window-application-${toString (index + 1)}";
  }) 9
))
// (listToAttrs (
  genList (index: {
    name = "mgt.switch-to-app-${toString (index + 1)}";
    value = "shell.switch-to-application-${toString (index + 1)}";
  }) 9
))
// (listToAttrs (
  genList (index: {
    name = "win.move-to-ws-${toString (index + 1)}";
    value = "wm.move-to-workspace-${toString (index + 1)}";
  }) 11
))
// (listToAttrs (
  genList (index: {
    name = "mgt.switch-to-ws-${toString (index + 1)}";
    value = "wm.switch-to-workspace-${toString (index + 1)}";
  }) 11
))
