{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.container =
    let
      containerSubmoduleType = lib.types.submodule {
        options.enable = lib.mkOption {
          type = with lib.types; bool;
          default = false;
          description = "Whether to enable the container submodule";
        };
        options.image = lib.mkOption {
          type = with lib.types; str;
          description = "Docker image to use for the container";
        };
        options.address = lib.mkOption {
          type = with lib.types; str;
          description = "Address to bind the container to";
        };
        options.environmentFiles = lib.mkOption {
          type = with lib.types; listOf str;
          description = "List of environment files to pass to the container";
        };
        options.dependsOn = lib.mkOption {
          type = with lib.types; listOf str;
          description = "List of containers that the container depends on";
        };
        options.dataDir = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "Directory to store container data";
        };
        options.networks = lib.mkOption {
          type = with lib.types; listOf anything;
          default = [ ];
          description = "List of networks to connect the container to";
        };
      };
    in
    {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = false;
        description = "Enable container supports";
      };
      containers = {
        dockhand = lib.mkOption {
          type = containerSubmoduleType;
          default = {
            enable = false;
            image = "fnsys/dockhand:8d7ce9eb-baseline";
            address = "127.0.0.1:2000";
            environmentFiles = [ ];
            dataDir = "/var/lib/dockhand";
          };
          description = "Dockhand container configuration";
        };
        postgres = {
          enable = lib.mkOption {
            type = with lib.types; bool;
            default = false;
            description = "Enable a PostgreSQL container";
          };
          instances = lib.mkOption {
            type = with lib.types; attrsOf (containerSubmoduleType);
            default = { };
            description = "Instances of PostgreSQL containers";
          };
        };
      };
    };
  config =
    let
      inherit (config.${namespace}.container) enable containers;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        environment.systemPackages = with pkgs; [
          buildah
          skopeo
          pods
          podman-compose
        ];
        virtualisation = {
          containers.enable = true;
          oci-containers.backend = "podman";
          podman = {
            enable = true;
            dockerCompat = true;
            dockerSocket.enable = true;
            autoPrune = {
              enable = true;
              dates = "weekly";
            };
            defaultNetwork.settings = {
              dns_enabled = true;
            };
          };
        };
      })
      (lib.mkIf (enable && containers.postgres.enable) (
        let
          enabledInstances = (lib.filterAttrs (_: instance: instance.enable) containers.postgres.instances);
          fallbackDataDir =
            name: instance: if instance.dataDir != null then instance.dataDir else "/var/lib/postgres-${name}";
        in
        {
          systemd.tmpfiles.rules = lib.mapAttrsToList (
            name: instance: "d ${fallbackDataDir name instance} 0700 70 70 -"
          ) enabledInstances;

          virtualisation.oci-containers = {
            containers = lib.mapAttrs' (
              name: instance:
              lib.nameValuePair "postgres-${name}" {
                ports = [ "${instance.address}:5432" ];
                volumes = [ "${fallbackDataDir name instance}:/var/lib/postgresql" ];
                inherit (instance)
                  image
                  environmentFiles
                  dependsOn
                  networks
                  ;
              }
            ) enabledInstances;
          };
        }
      ))
      (lib.mkIf (enable && containers.dockhand.enable) (
        let
          fallbackDataDir =
            instance: if instance.dataDir != null then instance.dataDir else "/var/lib/dockhand";
        in
        {
          systemd.tmpfiles.rules = [
            "d ${fallbackDataDir containers.dockhand} 0755 root root -"
          ];
          virtualisation.oci-containers.containers.dockhand = {
            ports = [ "${containers.dockhand.address}:3000" ];
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
              "${fallbackDataDir containers.dockhand}:/app/data"
            ];
            inherit (containers.dockhand)
              image
              dependsOn
              environmentFiles
              networks
              ;
          };

          systemd.services.podman-dockhand = {
            requires = [ "podman.socket" ];

            after = [
              "podman.socket"
              "network-online.target"
            ];

            wants = [ "network-online.target" ];

            serviceConfig = {
              Restart = lib.mkForce "on-failure";
              RestartSec = "5s";
            };

            unitConfig = {
              StartLimitIntervalSec = "60s";
              StartLimitBurst = 10;
            };
          };
        }
      ))
    ];
}
