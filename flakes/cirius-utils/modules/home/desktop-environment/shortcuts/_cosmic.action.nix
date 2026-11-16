let
  inherit (builtins) genList listToAttrs;
in
{
  # Native actions from cosmic-settings-daemon/config/src/shortcuts/action.rs.
  "capture.screenshot-ui" = "System(Screenshot)";
  "desktop.application-view" = "System(AppLibrary)";
  "desktop.overview" = "System(WorkspaceOverview)";
  "desktop.run-dialog" = "System(Launcher)";
  "display.brightness-down" = "System(BrightnessDown)";
  "display.brightness-up" = "System(BrightnessUp)";
  "input.switch-source" = "System(InputSourceSwitch)";
  "mgt.switch-apps" = "System(WindowSwitcher)";
  "mgt.switch-apps-back" = "System(WindowSwitcherPrevious)";
  "mgt.switch-ws-last" = "LastWorkspace";
  "mgt.switch-ws-left" = "PreviousWorkspace";
  "mgt.switch-ws-right" = "NextWorkspace";
  "mgt.switch-ws-up" = "PreviousWorkspace";
  "mgt.switch-ws-down" = "NextWorkspace";
  "win.begin-resize" = "Resizing(Outwards)";
  "win.close" = "Close";
  "win.minimize" = "Minimize";
  "win.to-mon-left" = "SendToOutput(Left)";
  "win.to-mon-right" = "SendToOutput(Right)";
  "win.to-mon-up" = "SendToOutput(Up)";
  "win.to-mon-down" = "SendToOutput(Down)";
  "win.to-ws-left" = "SendToPreviousWorkspace";
  "win.to-ws-right" = "SendToNextWorkspace";
  "win.to-ws-up" = "SendToPreviousWorkspace";
  "win.to-ws-down" = "SendToNextWorkspace";
  "win.toggle-fullscreen" = "Fullscreen";
  "win.toggle-maximize" = "Maximize";
  "win.toggle-on-all-workspaces" = "ToggleSticky";
  # Maximize is a toggle, and Move(Direction) is not KDE-style quick tiling.
  # Do not map win.maximize, win.unmaximize, or win.to-side-* to those actions.
}
// (listToAttrs (
  genList (index: {
    name = "mgt.switch-to-ws-${toString (index + 1)}";
    value = "Workspace(${toString (index + 1)})";
  }) 11
))
// (listToAttrs (
  genList (index: {
    name = "win.move-to-ws-${toString (index + 1)}";
    value = "SendToWorkspace(${toString (index + 1)})";
  }) 11
))
