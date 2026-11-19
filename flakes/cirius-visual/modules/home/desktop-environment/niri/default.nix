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
  inherit (config.${namespace}.desktop-environment) use niri wallpaper;
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
  interfaceFont = "Inter";
  iconTheme = "Tela-circle-dark";
  iconDirectory = "${pkgs.tela-circle-icon-theme}/share/icons/${iconTheme}";
  background = if wallpaper.dark == null then ./blue-hour.jpg else wallpaper.dark;
  palette = {
    ink = "101a29";
    surface = "172437";
    selection = "253b58";
    outline = "3c5370";
    muted = "9cb0ca";
    text = "e8eff8";
    accent = "99c4fc";
    urgent = "f2ab8e";
  };

  waybarConfig = pkgs.writeText "niri-waybar.json" (toJSON {
    layer = "top";
    height = 36;
    margin-top = 10;
    margin-left = 12;
    margin-right = 12;
    modules-left = [ "niri/workspaces" ];
    modules-center = [ "clock" ];
    modules-right = [
      "tray"
      "network"
      "pulseaudio"
    ];
    tray = {
      icon-size = 15;
      spacing = 8;
    };
    network = {
      format-wifi = "Wi-Fi {signalStrength}%";
      format-ethernet = "LAN";
      format-disconnected = "Offline";
      tooltip-format-wifi = "{essid} · {signalStrength}%";
    };
    pulseaudio = {
      format = "Vol {volume}%";
      format-muted = "Muted";
    };
    clock = {
      format = "{:%a %d %b · %H:%M}";
      tooltip-format = "{:%A, %d %B %Y}";
    };
  });
  waybarStyle = pkgs.writeText "niri-waybar.css" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: color: "@define-color ${name} #${color};") palette
    )
    + "\n"
    + builtins.readFile ./waybar.css
  );
  fuzzelConfig = pkgs.writeText "niri-fuzzel.ini" ''
    [main]
    font=${interfaceFont}:size=12
    icon-theme=${iconTheme}
    prompt=""
    placeholder=Search apps
    lines=8
    width=40
    horizontal-pad=16
    vertical-pad=13
    inner-pad=8
    line-height=30

    [colors]
    background=${palette.ink}fa
    text=${palette.text}ff
    prompt=${palette.accent}ff
    placeholder=${palette.muted}ff
    input=${palette.text}ff
    match=${palette.accent}ff
    selection=${palette.selection}ff
    selection-text=${palette.text}ff
    selection-match=${palette.accent}ff
    border=${palette.outline}ff

    [border]
    width=1
    radius=15
    selection-radius=8
  '';
  makoConfig = pkgs.writeText "niri-mako.conf" ''
    font=${interfaceFont} 11
    icon-path=${iconDirectory}/scalable/apps:${iconDirectory}/symbolic/status
    background-color=#${palette.ink}f5
    text-color=#${palette.text}
    border-color=#${palette.outline}
    border-size=1
    border-radius=12
    width=336
    margin=12
    padding=12,14

    [urgency=high]
    border-color=#${palette.urgent}
  '';
  swaylockConfig = pkgs.writeText "niri-swaylock.conf" ''
    font=${interfaceFont}
    image=${background}
    scaling=fill
    color=${palette.ink}
    indicator-radius=56
    indicator-thickness=5
    inside-color=${palette.ink}e8
    ring-color=${palette.outline}
    key-hl-color=${palette.accent}
    text-color=${palette.text}
    ring-ver-color=${palette.accent}
    ring-wrong-color=${palette.urgent}
    inside-ver-color=${palette.ink}
    inside-wrong-color=${palette.ink}
    text-ver-color=${palette.text}
    text-wrong-color=${palette.text}
    line-uses-inside
  '';
  lockCommand = "${locker} --config ${swaylockConfig}";
in
{
  options.${namespace}.desktop-environment.niri.enable =
    lib.mkEnableOption "the Niri daily-use configuration";

  config = lib.mkIf niri.enable {
    xdg.dataFile = {
      "fonts/niri-inter".source = "${pkgs.inter}/share/fonts";
      "icons/${iconTheme}".source = iconDirectory;
    };

    xdg.configFile."niri/config.kdl".text = ''
      hotkey-overlay { skip-at-startup; }

      layout {
          gaps 12
          background-color "transparent"
          focus-ring { off; }
          border {
              width 2
              active-color "#${palette.accent}"
              inactive-color "#${palette.outline}"
              urgent-color "#${palette.urgent}"
          }
          shadow {
              on
              softness 24
              offset x=0 y=7
              color "#00000066"
          }
      }

      window-rule {
          geometry-corner-radius 12
          clip-to-geometry true
      }

      overview {
          backdrop-color "#${palette.ink}"
      }

      layer-rule {
          match namespace="^wallpaper$"
          place-within-backdrop true
      }

      spawn-at-startup "${getExe pkgs.swaybg}" "--image" "${background}" "--mode" "fill"
      spawn-at-startup "${getExe pkgs.waybar}" "--config" "${waybarConfig}" "--style" "${waybarStyle}"
      spawn-at-startup "${getExe pkgs.mako}" "--config" "${makoConfig}"
      spawn-at-startup "${getExe pkgs.lxqt.lxqt-policykit}"
      spawn-at-startup "${getExe pkgs.swayidle}" "-w" \
          "timeout" "300" "${lockCommand} -f" \
          "timeout" "600" "${getExe pkgs.niri} msg action power-off-monitors" \
          "before-sleep" "${lockCommand} -f"

      ${lib.concatMapStringsSep "\n" (workspace: "workspace ${toJSON workspace}") workspaces}

      binds {
          Super+Shift+Slash { show-hotkey-overlay; }
          Super+A hotkey-overlay-title="Launch an application" { spawn "${getExe pkgs.fuzzel}" "--config" "${fuzzelConfig}"; }
          Super+T hotkey-overlay-title="Open Ghostty" { spawn "${getExe pkgs.ghostty}"; }
          Super+E hotkey-overlay-title="Open file manager" { spawn "${fileManager}"; }
          Super+Escape hotkey-overlay-title="Lock screen" { spawn "${locker}" "--config" "${swaylockConfig}"; }
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
