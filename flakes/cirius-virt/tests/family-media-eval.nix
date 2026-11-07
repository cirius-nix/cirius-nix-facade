# nix-instantiate --eval --strict --json --arg nixpkgs /path/to/nixpkgs this-file
{ nixpkgs }:
let
  lib = import (nixpkgs + "/lib");
  evaluate =
    settings:
    (import (nixpkgs + "/nixos/lib/eval-config.nix") {
      system = "x86_64-linux";
      specialArgs.namespace = "cnix-virt";
      modules = [
        ../modules/nixos/family-media
        {
          boot.isContainer = true;
          system.stateVersion = "25.11";
          cnix-virt.family-media = settings;
        }
      ];
    }).config;
  disabled = evaluate { };
  enabled = evaluate {
    enable = true;
    jellyfin.libraryPaths = [ "/srv/media/Videos" ];
    immich.libraryPaths = [ "/srv/media/Pictures" ];
  };
  onlyJellyfin = evaluate {
    enable = true;
    immich.enable = false;
  };
  badPaths = evaluate {
    enable = true;
    immich.libraryPaths = [ "/mnt/main-data/Pictures" ];
  };
  checks = {
    optIn = !disabled.services.jellyfin.enable && !disabled.services.immich.enable;
    bothEnabled = enabled.services.jellyfin.enable && enabled.services.immich.enable;
    individualOptOut = onlyJellyfin.services.jellyfin.enable && !onlyJellyfin.services.immich.enable;
    immichLoopback = enabled.services.immich.host == "127.0.0.1";
    noOpenFirewall = !enabled.services.jellyfin.openFirewall && !enabled.services.immich.openFirewall;
    noPortsAdded =
      enabled.networking.firewall.allowedTCPPorts == [ ]
      && enabled.networking.firewall.allowedUDPPorts == [ ];
    separateUsers =
      enabled.services.immich.user == "immich" && enabled.services.jellyfin.user == "jellyfin";
    ssdUploads = enabled.services.immich.mediaLocation == "/var/lib/immich";
    socketDatabase = enabled.services.immich.database.host == "/run/postgresql";
    readonlyLibrary =
      enabled.systemd.services.immich-server.serviceConfig.BindReadOnlyPaths == [ "/srv/media/Pictures" ];
    mountsRequired = builtins.elem "/srv/media/Pictures" enabled.systemd.services.immich-server.unitConfig.RequiresMountsFor;
    rawDiskHidden = builtins.elem "-/mnt" enabled.systemd.services.immich-server.serviceConfig.InaccessiblePaths;
    systemReadonly = enabled.systemd.services.jellyfin.serviceConfig.ProtectSystem == "strict";
    bindConfiguredBeforeStart = lib.hasInfix "private-network.py" enabled.systemd.services.jellyfin.preStart;
    enabledAssertions = builtins.all (item: item.assertion) enabled.assertions;
    badPathsRejected = !(builtins.all (item: item.assertion) badPaths.assertions);
  };
in
assert lib.assertMsg (builtins.all (value: value) (builtins.attrValues checks)) (
  builtins.toJSON checks
);
checks
