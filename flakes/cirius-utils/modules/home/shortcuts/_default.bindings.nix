let
  inherit (builtins) genList listToAttrs;

  bind = keys: [ keys ];

  emptyNumberedBindings =
    prefix: count:
    listToAttrs (
      genList (index: {
        name = "${prefix}-${toString (index + 1)}";
        value = [ ];
      }) count
    );

  numberedWorkspaceBindings =
    prefix: modifiers:
    listToAttrs (
      genList (
        index:
        let
          workspace = index + 1;
        in
        {
          name = "${prefix}-${toString workspace}";
          value = if workspace <= 9 then bind (modifiers ++ [ (toString workspace) ]) else [ ];
        }
      ) 11
    );
in
{
  # Capture
  "capture.screen-recording-ui" = [ ];
  "capture.screenshot" = [ ];
  "capture.screenshot-ui" = bind [
    "Meta"
    "Shift"
    "s"
  ];
  "capture.screenshot-window" = bind [
    "Meta"
    "Shift"
    "w"
  ];

  # Desktop shell
  "desktop.application-view" = [ ];
  "desktop.message-tray" = bind [
    "Meta"
    "n"
  ];
  "desktop.overview" = bind [
    "Meta"
    "d"
  ];
  "desktop.quick-settings" = [ ];
  "desktop.run-dialog" = [ ];
  "desktop.shift-overview-down" = [ ];
  "desktop.shift-overview-up" = [ ];
  "desktop.show" = bind [
    "Meta"
    "Shift"
    "d"
  ];

  # Displays
  "display.brightness-cycle" = bind [ "XF86MonBrightnessCycle" ];
  "display.brightness-cycle-monitor" = bind [
    "Shift"
    "XF86MonBrightnessCycle"
  ];
  "display.brightness-down" = bind [ "XF86MonBrightnessDown" ];
  "display.brightness-down-monitor" = bind [
    "Shift"
    "XF86MonBrightnessDown"
  ];
  "display.brightness-up" = bind [ "XF86MonBrightnessUp" ];
  "display.brightness-up-monitor" = bind [
    "Shift"
    "XF86MonBrightnessUp"
  ];

  # Input sources
  "input.switch-source" = [
    [
      "Meta"
      "Shift"
      "space"
    ]
    [ "XF86Keyboard" ]
  ];
  "input.switch-source-back" = [ ];

  # Window and workspace management
  "mgt.cycle-group" = [ ];
  "mgt.cycle-group-back" = [ ];
  "mgt.cycle-panels" = [ ];
  "mgt.cycle-panels-back" = [ ];
  "mgt.cycle-windows" = [ ];
  "mgt.cycle-windows-back" = [ ];
  "mgt.switch-apps" = bind [
    "Alt"
    "Tab"
  ];
  "mgt.switch-apps-back" = bind [
    "Alt"
    "Shift"
    "Tab"
  ];
  "mgt.switch-group" = [ ];
  "mgt.switch-group-back" = [ ];
  "mgt.switch-panels" = [ ];
  "mgt.switch-panels-back" = [ ];
  "mgt.switch-windows" = [ ];
  "mgt.switch-windows-back" = [ ];
  "mgt.switch-ws-down" = [ ];
  "mgt.switch-ws-last" = [ ];
  "mgt.switch-ws-left" = bind [
    "Meta"
    "Shift"
    "Tab"
  ];
  "mgt.switch-ws-right" = bind [
    "Meta"
    "Tab"
  ];
  "mgt.switch-ws-up" = [ ];

  # Windows
  "win.activate-menu" = bind [
    "Alt"
    "F1"
  ];
  "win.always-on-top" = [ ];
  "win.begin-move" = bind [
    "Meta"
    "Alt"
    "m"
  ];
  "win.begin-resize" = bind [
    "Meta"
    "Alt"
    "r"
  ];
  "win.close" = [
    [
      "Alt"
      "F4"
    ]
    [
      "Meta"
      "q"
    ]
  ];
  "win.lower" = [ ];
  "win.maximize" = bind [
    "Meta"
    "Up"
  ];
  "win.maximize-horizontally" = [ ];
  "win.maximize-vertically" = [ ];
  "win.minimize" = bind [
    "Meta"
    "m"
  ];
  "win.raise" = [ ];
  "win.raise-or-lower" = [ ];
  "win.set-spew-mark" = [ ];
  "win.to-center" = [ ];
  "win.to-corner-ne" = [ ];
  "win.to-corner-nw" = [ ];
  "win.to-corner-se" = [ ];
  "win.to-corner-sw" = [ ];
  "win.to-mon-down" = bind [
    "Meta"
    "Shift"
    "Page_Down"
  ];
  "win.to-mon-left" = [ ];
  "win.to-mon-right" = [ ];
  "win.to-mon-up" = bind [
    "Meta"
    "Shift"
    "Page_Up"
  ];
  "win.to-side-e" = [ ];
  "win.to-side-n" = [ ];
  "win.to-side-s" = [ ];
  "win.to-side-w" = [ ];
  "win.to-ws-down" = [ ];
  "win.to-ws-left" = bind [
    "Meta"
    "Shift"
    "Left"
  ];
  "win.to-ws-right" = bind [
    "Meta"
    "Shift"
    "Right"
  ];
  "win.to-ws-up" = [ ];
  "win.toggle-above" = [ ];
  "win.toggle-fullscreen" = bind [
    "Alt"
    "F11"
  ];
  "win.toggle-maximize" = [ ];
  "win.toggle-on-all-workspaces" = [ ];
  "win.unmaximize" = bind [
    "Meta"
    "Down"
  ];
}
// (emptyNumberedBindings "mgt.open-new-win" 9)
// (emptyNumberedBindings "mgt.switch-to-app" 9)
// (numberedWorkspaceBindings "win.move-to-ws" [
  "Meta"
  "Shift"
])
// (numberedWorkspaceBindings "mgt.switch-to-ws" [ "Meta" ])
