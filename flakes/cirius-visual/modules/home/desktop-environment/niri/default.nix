{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe getExe';
  inherit (builtins) toJSON;
  inherit (config.${namespace}.desktop-environment) use niri;
  workspaces = map toString (lib.range 1 9);
  fileManager = getExe (
    {
      cosmic = pkgs.cosmic-files;
      gnome = pkgs.nautilus;
      kde = pkgs.kdePackages.dolphin;
    }
    .${use} or pkgs.xfce.thunar
  );
  locker = getExe pkgs.swaylock;
  wpctl = getExe' pkgs.wireplumber "wpctl";
  makoctl = getExe' pkgs.mako "makoctl";
  waybarConfig = pkgs.writeText "niri-waybar.json" (toJSON {
    layer = "top";
    modules-left = [ "niri/workspaces" ];
    modules-right = [
      "tray"
      "network"
      "pulseaudio"
      "clock"
    ];
    "niri/workspaces".format = "{name}";
    network = {
      format-wifi = "{essid}";
      format-ethernet = "Ethernet";
      format-disconnected = "Offline";
    };
    pulseaudio = {
      format = "{volume}%";
      format-muted = "Muted";
    };
    clock.format = "{:%a %d %b  %H:%M}";
  });
in
{
  options.${namespace}.desktop-environment.niri.enable =
    lib.mkEnableOption "the Niri daily-use configuration";

  config = lib.mkIf niri.enable {
    xdg.configFile."niri/config.kdl".text = ''
      hotkey-overlay { skip-at-startup; }

      spawn-at-startup "${getExe pkgs.waybar}" "--config" "${waybarConfig}"
      spawn-at-startup "${getExe pkgs.mako}"
      spawn-at-startup "${getExe pkgs.lxqt.lxqt-policykit}"
      spawn-at-startup "${getExe pkgs.swayidle}" "-w" \
          "timeout" "300" "${locker} -f" \
          "timeout" "600" "${getExe pkgs.niri} msg action power-off-monitors" \
          "before-sleep" "${locker} -f"

      ${lib.concatMapStringsSep "\n" (workspace: "workspace ${toJSON workspace}") workspaces}

      binds {
          Super+Shift+Slash { show-hotkey-overlay; }
          Super+A hotkey-overlay-title="Launch an application" { spawn "${getExe pkgs.fuzzel}"; }
          Super+T hotkey-overlay-title="Open Ghostty" { spawn "${getExe pkgs.ghostty}"; }
          Super+E hotkey-overlay-title="Open file manager" { spawn "${fileManager}"; }
          Super+Escape hotkey-overlay-title="Lock screen" { spawn "${locker}"; }
          Super+Shift+E { quit; }

          // Alt+Tab and Alt+Shift+Tab use Niri's built-in recent windows switcher.
          Super+D repeat=false { toggle-overview; }
          Super+Q repeat=false { close-window; }
          Alt+F4 repeat=false { close-window; }
          Super+Up repeat=false { maximize-window-to-edges; }
          Alt+F11 repeat=false { fullscreen-window; }
          Super+V { toggle-window-floating; }

          Super+Left { focus-column-left; }
          Super+Right { focus-column-right; }
          Super+Ctrl+Left { move-column-left; }
          Super+Ctrl+Right { move-column-right; }
          Super+Alt+Up { focus-window-up; }
          Super+Alt+Down { focus-window-down; }
          Super+Ctrl+Up { move-window-up; }
          Super+Ctrl+Down { move-window-down; }
          Super+BracketLeft { consume-or-expel-window-left; }
          Super+BracketRight { consume-or-expel-window-right; }
          Super+R { switch-preset-column-width; }

          Super+Tab { focus-workspace-down; }
          Super+Shift+Tab { focus-workspace-up; }
          Super+Shift+Left { move-window-to-workspace-up; }
          Super+Shift+Right { move-window-to-workspace-down; }
          Super+Shift+Page_Up { move-window-to-monitor-up; }
          Super+Shift+Page_Down { move-window-to-monitor-down; }
          Super+Alt+Left { focus-monitor-left; }
          Super+Alt+Right { focus-monitor-right; }
          Super+Ctrl+Shift+Left { move-window-to-monitor-left; }
          Super+Ctrl+Shift+Right { move-window-to-monitor-right; }
          ${lib.concatMapStringsSep "\n    " (
            workspace:
            "Super+${workspace} { focus-workspace ${toJSON workspace}; }\n    Super+Shift+${workspace} { move-window-to-workspace ${toJSON workspace}; }"
          ) workspaces}

          Print { screenshot; }
          Super+Shift+S { screenshot; }
          Super+Shift+W { screenshot-window; }
          Super+N hotkey-overlay-title="Recall last notification" { spawn "${makoctl}" "restore"; }

          XF86AudioRaiseVolume allow-when-locked=true { spawn "${wpctl}" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "5%+"; }
          XF86AudioLowerVolume allow-when-locked=true { spawn "${wpctl}" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
          XF86AudioMute allow-when-locked=true { spawn "${wpctl}" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          XF86AudioMicMute allow-when-locked=true { spawn "${wpctl}" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
          XF86AudioPlay { spawn "${getExe pkgs.playerctl}" "play-pause"; }
          XF86AudioNext { spawn "${getExe pkgs.playerctl}" "next"; }
          XF86AudioPrev { spawn "${getExe pkgs.playerctl}" "previous"; }
          XF86MonBrightnessUp allow-when-locked=true { spawn "${getExe pkgs.brightnessctl}" "--class=backlight" "set" "+10%"; }
          XF86MonBrightnessDown allow-when-locked=true { spawn "${getExe pkgs.brightnessctl}" "--class=backlight" "set" "10%-"; }
      }
    '';
  };
}
