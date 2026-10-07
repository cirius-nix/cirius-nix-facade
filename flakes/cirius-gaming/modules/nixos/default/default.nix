{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports = [
    inputs.eden.nixosModules.default
  ]
  ++ (attrValues (removeAttrs inputs.self.nixosModules [ "default" ]));
  options.${namespace} = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use recommended packages for gaming";
    };
    usePlatforms = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Enable gaming platforms.";
    };
    gamescope = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable gamescope";
      };
      hdr = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable HDR support in gamescope";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) useRecommendedPackages gamescope usePlatforms;
      ifPlatform = x: lib.elem x usePlatforms;
    in
    lib.mkMerge [
      (lib.mkIf useRecommendedPackages {
        environment.systemPackages = with pkgs; [
          protonup-qt
          wine
          mangohud
          protontricks
          protonplus
          shadps4
          shadps4-qtlauncher
        ];
        hardware.graphics.enable32Bit = true;
        programs = {
          gamemode.enable = true;
        };
      })

      (lib.mkIf (ifPlatform "lutris") {
        environment.systemPackages = with pkgs; [
          lutris
        ];
      })

      (lib.mkIf (ifPlatform "steam") {
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          gamescopeSession = {
            inherit (gamescope) enable;
          };
        };
      })

      (lib.mkIf gamescope.enable {
        programs.gamescope = {
          enable = true;
          capSysNice = true;
          enableWsi = gamescope.hdr;
        };
      })
    ];
}
