{
  lib,
  cfg,
  doopSource,
}:
let
  apps = cfg.containers;
  service =
    image: attrs:
    {
      inherit image;
      platform = "linux/arm64";
      restart = "unless-stopped";
    }
    // attrs;
  postgres =
    image: database: volume: password:
    service image {
      environment = {
        POSTGRES_DB = database;
        POSTGRES_USER = database;
        POSTGRES_PASSWORD = password;
      };
      volumes = [ volume ];
      healthcheck = {
        test = [
          "CMD-SHELL"
          "pg_isready -U ${database} -d ${database}"
        ];
        interval = "5s";
        timeout = "5s";
        retries = 30;
      };
    };
  healthy = name: { ${name}.condition = "service_healthy"; };
  penpotImage = component: "docker.io/penpotapp/${component}:${apps.penpot.version}";
  penpotDatabase = {
    PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
    PENPOT_DATABASE_USERNAME = "penpot";
    PENPOT_DATABASE_PASSWORD = "\${PENPOT_DATABASE_PASSWORD:?Run cnix-containers up}";
  };
  penpotCommon = {
    PENPOT_PUBLIC_URI = apps.penpot.publicUri;
    PENPOT_SECRET_KEY = "\${PENPOT_SECRET_KEY:?Run cnix-containers up}";
  };
  flags =
    "disable-email-verification enable-smtp enable-prepl-server enable-mcp enable-admin-console"
    + lib.optionalString (lib.hasPrefix "http://" apps.penpot.publicUri) " disable-secure-session-cookies";
in
{
  services =
    lib.optionalAttrs apps.doop.enable {
      doop = service "cirius-doop:0.13.0" {
        build.context = toString doopSource;
        pull_policy = "never";
        ports = [ "${apps.doop.address}:4400" ];
        volumes = [ "doop-data:/app/data" ];
        environment = {
          NODE_ENV = "production";
          PORT = "4400";
          BETTER_AUTH_URL = apps.doop.publicUri;
          BETTER_AUTH_SECRET = "\${DOOP_AUTH_SECRET:?Run cnix-containers up}";
          SECRETS_ENCRYPTION_KEYS = "\${DOOP_ENCRYPTION_KEYS:?Run cnix-containers up}";
        };
      };
    }
    // lib.optionalAttrs apps.dockhand.enable {
      dockhand = service apps.dockhand.image {
        ports = [ "${apps.dockhand.address}:3000" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "dockhand-data:/app/data"
        ];
        environment.DATABASE_URL = "postgres://dockhand:\${DOCKHAND_DATABASE_PASSWORD:?Run cnix-containers up}@dockhand-postgres:5432/dockhand";
        depends_on = healthy "dockhand-postgres";
      };
      dockhand-postgres =
        postgres "docker.io/library/postgres:18-alpine" "dockhand" "dockhand-postgres:/var/lib/postgresql"
          "\${DOCKHAND_DATABASE_PASSWORD:?Run cnix-containers up}";
    }
    // lib.optionalAttrs apps.penpot.enable {
      penpot-frontend = service (penpotImage "frontend") {
        ports = [ "${apps.penpot.address}:8080" ];
        volumes = [ "penpot-assets:/opt/data/assets" ];
        depends_on = [
          "penpot-backend"
          "penpot-admin-console"
          "penpot-exporter"
          "penpot-mcp"
        ];
        environment = {
          PENPOT_FLAGS = flags;
          PENPOT_PUBLIC_URI = apps.penpot.publicUri;
          PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
          PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
        };
      };
      penpot-backend = service (penpotImage "backend") {
        volumes = [ "penpot-assets:/opt/data/assets" ];
        depends_on = healthy "penpot-postgres" // {
          penpot-valkey.condition = "service_started";
        };
        environment =
          penpotDatabase
          // penpotCommon
          // {
            PENPOT_FLAGS = flags;
            PENPOT_HTTP_SERVER_MAX_BODY_SIZE = "367001600";
            PENPOT_ADMIN_CONSOLE_URI = "http://penpot-admin-console:3000";
            PENPOT_REDIS_URI = "redis://penpot-valkey/0";
            PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
            PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
            PENPOT_TELEMETRY_ENABLED = "false";
            PENPOT_SMTP_DEFAULT_FROM = "no-reply@example.com";
            PENPOT_SMTP_DEFAULT_REPLY_TO = "no-reply@example.com";
            PENPOT_SMTP_HOST = "penpot-mailpit";
            PENPOT_SMTP_PORT = "1025";
            PENPOT_SMTP_TLS = "false";
            PENPOT_SMTP_SSL = "false";
          };
      };
      penpot-admin-console = service (penpotImage "admin-console") {
        depends_on = healthy "penpot-postgres";
        environment =
          penpotDatabase
          // penpotCommon
          // {
            PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
          };
      };
      penpot-mcp = service (penpotImage "mcp") { depends_on = [ "penpot-backend" ]; };
      penpot-exporter = service (penpotImage "exporter") {
        depends_on = [ "penpot-valkey" ];
        environment = penpotCommon // {
          PENPOT_FLAGS = flags;
          PENPOT_INTERNAL_URI = "http://penpot-frontend:8080";
          PENPOT_REDIS_URI = "redis://penpot-valkey/0";
        };
      };
      penpot-postgres =
        postgres "docker.io/library/postgres:15" "penpot" "penpot-postgres:/var/lib/postgresql/data"
          "\${PENPOT_DATABASE_PASSWORD:?Run cnix-containers up}";
      penpot-valkey = service "docker.io/valkey/valkey:8.1" {
        command = [
          "valkey-server"
          "--maxmemory"
          "128mb"
          "--maxmemory-policy"
          "volatile-lfu"
        ];
      };
      penpot-mailpit = service "docker.io/axllent/mailpit:v1" { ports = [ "127.0.0.1:8025:8025" ]; };
    };
  volumes = lib.genAttrs (
    lib.optional apps.doop.enable "doop-data"
    ++ lib.optionals apps.dockhand.enable [
      "dockhand-data"
      "dockhand-postgres"
    ]
    ++ lib.optionals apps.penpot.enable [
      "penpot-assets"
      "penpot-postgres"
    ]
  ) (_: { });
}
