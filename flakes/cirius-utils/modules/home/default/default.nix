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
          nix-rb = "${lib.getExe pkgs.nh} os rebuild ${settings.dotFileDir}#${host}";
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
    ];
}
