{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  host,
  ...
}:
{
  imports =
    (with inputs; [
      nix-flatpak.homeManagerModules.nix-flatpak
      plasma-manager.homeModules.plasma-manager
    ])
    ++ (builtins.attrValues (removeAttrs inputs.self.homeModules [ "default" ]));

  options.${namespace} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Cirius Utils.";
    };
    settings = {
      dotFileDir = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "The directory where dotfiles are stored. If null, defaults to ~/.dotfiles.";
      };
      enableBootLogCapture = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable boot log capture.";
      };
      managedDesktopEnvironment = lib.mkOption {
        type = lib.types.enum [
          "unset"
          "kde"
          "gnome"
        ];
        default = "unset";
        description = "The desktop environment to manage. If unset, will not manage any desktop environment.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) enable settings;
      hmLib = inputs.home-manager.lib;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [ nh ];
      })

      (lib.mkIf (enable && settings.dotFileDir != null) {
        programs.fish.shellAbbrs = {
          nr = ''
            nix repl --repl-overlays \
            ${settings.dotFileDir}/repl.${config.home.username}.${host}.nix \
            ${settings.dotFileDir}
          '';
          nix-sw = "${lib.getExe pkgs.nh} os switch ${settings.dotFileDir}#${host}";
          nix-rb = "${lib.getExe pkgs.nh} os build ${settings.dotFileDir}#${host}";
          nix-b = "${lib.getExe pkgs.nh} os boot ${settings.dotFileDir}#${host}";
          nix-ls-gen = "sudo nix-env --profile /nix/var/nix/profiles/system --list-generations";
          nix-del-gens = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old";
          nix-clean-store = "sudo nix-store --gc";
        };
      })

      (lib.mkIf (enable && settings.enableBootLogCapture) {
        home.activation.createBootLogDir = hmLib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${config.xdg.stateHome}/boot-logs"
        '';
        programs.fish.shellAbbrs = {
          make-boot-log = "sudo journalctl -b -o short-precise --no-pager > ${config.xdg.stateHome}/boot-logs/$(date +%Y%m%d-%H%M%S).log";
        };
      })

      (lib.mkIf (enable && settings.managedDesktopEnvironment == "kde") {
        home.packages = with pkgs.kdePackages; [ kjournald ];
        programs.plasma = {
          windows = {
            allowWindowsToRememberPositions = true;
          };
          workspace = {
            clickItemTo = "select"; # open | select
            enableMiddleClickPaste = true;
          };
          session = {
            general.askForConfirmationOnLogout = true;
            sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
          };
        };
      })

      (lib.mkIf (enable && settings.managedDesktopEnvironment == "gnome") {
        dconf = {
          settings = {
            "org/gnome/desktop/peripherals/keyboard" = {
              # prevent repeating keys to be too fast
              repeat = true;
              repeat-interval = 30;

              # Key repeat delay when keeping a key pressed (in milliseconds). The default is 500ms.
              delay = 500;
            };
          };
        };
      })
    ];
}
