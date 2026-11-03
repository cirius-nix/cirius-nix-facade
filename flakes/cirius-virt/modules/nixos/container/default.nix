{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.container =
    let
      cnix-lib = inputs.cirius-lib.lib;
      containerSubmoduleType = lib.types.submodule {
        options.enable = cnix-lib.mkBoolOpt {
          default = false;
          description = "Whether to enable the container";
        };
        options.image = cnix-lib.mkStrOpt {
          nullable = true;
          description = "Container image to use";
        };
        options.address = cnix-lib.mkStrOpt {
          description = "Address to bind the container to";
        };
        options.environmentFiles = cnix-lib.mkListOpt {
          ofType = with lib.types; str;
          default = [ ];
          description = "List of environment files to pass to the container";
        };
        options.dependsOn = cnix-lib.mkListOpt {
          ofType = with lib.types; str;
          default = [ ];
          description = "List of containers to depend on";
        };
        options.dataDir = cnix-lib.mkStrOpt {
          nullable = true;
          description = "Data directory for the container";
        };
        options.networks = cnix-lib.mkListOpt {
          ofType = with lib.types; str;
          default = [ ];
          description = "List of networks to connect the container to";
        };
      };
    in
    {
      enable = cnix-lib.mkBoolOpt {
        default = false;
        description = "Whether to enable the container module";
      };
      containers = {
        dockhand = cnix-lib.mkPrimOpt containerSubmoduleType {
          default = {
            enable = false;
            image = "fnsys/dockhand:8d7ce9eb-baseline";
            address = "127.0.0.1:2000";
            environmentFiles = [ ];
            dataDir = "/var/lib/dockhand";
          };
          description = "Configuration for the Dockhand container";
        };
        postgres = {
          enable = cnix-lib.mkBoolOpt {
            default = false;
            description = "Whether to enable the PostgreSQL container module";
          };
          instances = cnix-lib.mkAttrsOpt {
            ofType = containerSubmoduleType;
            default = { };
            description = "Instances of PostgreSQL containers";
          };
        };
        penpot = {
          enable = cnix-lib.mkBoolOpt {
            default = false;
            description = "Whether to enable the Penpot containers";
          };
          version = cnix-lib.mkStrOpt {
            default = "2.18";
            description = "Penpot image tag to use for all Penpot services";
          };
          address = cnix-lib.mkStrOpt {
            default = "127.0.0.1:9001";
            description = "Address to bind the Penpot frontend to";
          };
          publicUri = cnix-lib.mkStrOpt {
            default = "http://localhost:9001";
            description = "Public URI used to access Penpot";
          };
          dataDir = cnix-lib.mkStrOpt {
            nullable = true;
            description = "Data directory for the Penpot containers";
          };
          environmentFiles = cnix-lib.mkListOpt {
            ofType = with lib.types; str;
            default = [ ];
            description = "List of environment files passed to the Penpot services that need the secret key (backend, admin-console, exporter); values override the generated secret file";
          };
          flags = cnix-lib.mkListOpt {
            ofType = with lib.types; str;
            default = [
              "disable-email-verification"
              "enable-smtp"
              "enable-prepl-server"
              "disable-secure-session-cookies"
              "enable-mcp"
              "enable-admin-console"
            ];
            description = "Penpot feature flags passed via PENPOT_FLAGS";
          };
          telemetryEnabled = cnix-lib.mkBoolOpt {
            default = true;
            description = "Whether to enable Penpot telemetry";
          };
          mailpit = {
            enable = cnix-lib.mkBoolOpt {
              default = true;
              description = "Whether to enable the Mailpit SMTP catch-all container";
            };
            address = cnix-lib.mkStrOpt {
              default = "127.0.0.1:8025";
              description = "Address to bind the Mailpit web UI to";
            };
          };
        };
      };
    };
  config =
    let
      inherit (config.${namespace}.container) enable containers;
      penpot = containers.penpot;
      penpotDataDir = if penpot.dataDir != null then penpot.dataDir else "/var/lib/penpot";
      penpotSecretEnvFile = "${penpotDataDir}/penpot.env";
      penpotFlags = lib.concatStringsSep " " penpot.flags;
      penpotDatabaseEnv = {
        PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
        PENPOT_DATABASE_USERNAME = "penpot";
        PENPOT_DATABASE_PASSWORD = "penpot";
      };
      penpotSecretEnvironmentFiles = [ penpotSecretEnvFile ] ++ penpot.environmentFiles;
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

      (lib.mkIf (enable && penpot.enable) {
        systemd.tmpfiles.rules = [
          "d ${penpotDataDir} 0755 root root -"
          "d ${penpotDataDir}/assets 0755 root root -"
          "d ${penpotDataDir}/postgres 0700 root root -"
        ];

        # Generate a stable PENPOT_SECRET_KEY on first activation. More
        # variables can be added to ${penpotSecretEnvFile}, or overridden
        # through `environmentFiles` (e.g. for an external SMTP provider).
        system.activationScripts.penpot-secret = ''
          mkdir -p ${penpotDataDir}
          if [ ! -f ${penpotSecretEnvFile} ]; then
            echo "PENPOT_SECRET_KEY=$(head -c 64 /dev/urandom | ${lib.getExe' pkgs.coreutils "base64"} -w0)" > ${penpotSecretEnvFile}
            chmod 600 ${penpotSecretEnvFile}
          fi
        '';

        virtualisation.oci-containers.containers = {
          penpot-frontend = {
            image = "docker.io/penpotapp/frontend:${penpot.version}";
            ports = [ "${penpot.address}:8080" ];
            volumes = [ "${penpotDataDir}/assets:/opt/data/assets" ];
            dependsOn = [
              "penpot-backend"
              "penpot-admin-console"
              "penpot-mcp"
              "penpot-exporter"
            ];
            environment = {
              PENPOT_FLAGS = penpotFlags;
              PENPOT_PUBLIC_URI = penpot.publicUri;
              PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
              PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
            };
          };

          penpot-backend = {
            image = "docker.io/penpotapp/backend:${penpot.version}";
            volumes = [ "${penpotDataDir}/assets:/opt/data/assets" ];
            dependsOn = [
              "penpot-postgres"
              "penpot-valkey"
            ];
            environmentFiles = penpotSecretEnvironmentFiles;
            environment = penpotDatabaseEnv // {
              PENPOT_FLAGS = penpotFlags;
              PENPOT_PUBLIC_URI = penpot.publicUri;
              PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
              PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
              PENPOT_REDIS_URI = "redis://penpot-valkey/0";
              PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
              PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
              PENPOT_TELEMETRY_ENABLED = lib.boolToString penpot.telemetryEnabled;
              PENPOT_TELEMETRY_REFERER = "compose";
              PENPOT_SMTP_DEFAULT_FROM = "no-reply@example.com";
              PENPOT_SMTP_DEFAULT_REPLY_TO = "no-reply@example.com";
              PENPOT_SMTP_HOST = "penpot-mailpit";
              PENPOT_SMTP_PORT = "1025";
              PENPOT_SMTP_TLS = "false";
              PENPOT_SMTP_SSL = "false";
            };
          };

          penpot-admin-console = {
            image = "docker.io/penpotapp/admin-console:${penpot.version}";
            dependsOn = [ "penpot-postgres" ];
            environmentFiles = penpotSecretEnvironmentFiles;
            environment = penpotDatabaseEnv // {
              PENPOT_PUBLIC_URI = penpot.publicUri;
              PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
            };
          };

          penpot-mcp = {
            image = "docker.io/penpotapp/mcp:${penpot.version}";
            dependsOn = [ "penpot-backend" ];
          };

          penpot-exporter = {
            image = "docker.io/penpotapp/exporter:${penpot.version}";
            dependsOn = [ "penpot-valkey" ];
            environmentFiles = penpotSecretEnvironmentFiles;
            environment = {
              PENPOT_FLAGS = penpotFlags;
              PENPOT_PUBLIC_URI = penpot.publicUri;
              PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
              PENPOT_REDIS_URI = "redis://penpot-valkey/0";
            };
          };

          penpot-postgres = {
            image = "docker.io/library/postgres:15";
            volumes = [ "${penpotDataDir}/postgres:/var/lib/postgresql/data" ];
            environment = {
              POSTGRES_INITDB_ARGS = "--data-checksums";
              POSTGRES_DB = "penpot";
              POSTGRES_USER = "penpot";
              POSTGRES_PASSWORD = "penpot";
            };
          };

          penpot-valkey = {
            image = "docker.io/valkey/valkey:8.1";
            dependsOn = [ "penpot-postgres" ];
            environment.VALKEY_EXTRA_FLAGS = "--maxmemory 128mb --maxmemory-policy volatile-lfu";
          };
        }
        // lib.optionalAttrs penpot.mailpit.enable {
          penpot-mailpit = {
            image = "docker.io/axllent/mailpit:v1";
            ports = [ "${penpot.mailpit.address}:8025" ];
            dependsOn = [ "penpot-backend" ];
          };
        };
      })
    ];
}
