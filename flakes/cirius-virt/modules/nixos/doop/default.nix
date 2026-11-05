{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.container.containers.doop;
  version = "0.13.0";
  localImage = "localhost/doop:${version}";
  source = pkgs.fetchFromGitHub {
    owner = "kgoedecke";
    repo = "doop";
    rev = "v${version}";
    hash = "sha256-kQiB/+89z2wSme8GEL+dR+De5A/AZzKeHnJsZtok1ck=";
  };
  # Avoid Podman's interactive short-name registry resolution during boot.
  buildContext = pkgs.runCommand "doop-${version}-container-source" { } ''
    mkdir -p "$out"
    cp -r ${source}/. "$out/"
    chmod -R u+w "$out"
    substituteInPlace "$out/Dockerfile" \
      --replace-fail 'FROM oven/bun:1' 'FROM docker.io/oven/bun:1' \
      --replace-fail 'FROM node:22-slim' 'FROM docker.io/library/node:22-slim'
  '';
  secretDir = "/var/lib/doop-secrets";
  secretFile = "${secretDir}/environment";
  buildLocally = cfg.image == null;
in
{
  options.${namespace}.container.containers.doop = {
    enable = lib.mkEnableOption "the self-hosted Doop design canvas";
    image = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "Prebuilt OCI image to use. Null builds the pinned upstream Dockerfile locally.";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:4400";
      description = "Host address and port to bind the Doop web app, API, and MCP server to.";
    };
    publicUri = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:4400";
      description = "Public origin used for authentication and absolute URLs.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/doop";
      description = "Persistent directory containing the embedded database and uploaded assets.";
    };
    environmentFiles = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Runtime environment files for optional integrations or overrides of the generated secrets.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.container.enable = lib.mkDefault true;

    assertions = [
      {
        assertion = config.${namespace}.container.enable;
        message = "Enabling Doop requires the parent container module to be enabled.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.dataDir && cfg.dataDir != "/";
        message = "Doop dataDir must be an absolute directory other than /.";
      }
      {
        assertion =
          !(cfg.dataDir == secretDir || lib.hasPrefix "${lib.removeSuffix "/" cfg.dataDir}/" secretDir);
        message = "Doop dataDir must not contain /var/lib/doop-secrets, which stores credentials outside the container volume.";
      }
    ];

    virtualisation.oci-containers.containers.doop = {
      image = if buildLocally then localImage else cfg.image;
      ports = [ "${cfg.address}:4400" ];
      volumes = [ "${cfg.dataDir}:/app/data" ];
      environment = {
        NODE_ENV = "production";
        PORT = "4400";
        BETTER_AUTH_URL = cfg.publicUri;
      };
      environmentFiles = [ secretFile ] ++ cfg.environmentFiles;
      pull = if buildLocally then "never" else "missing";
    };

    systemd.services.doop-secrets = {
      description = "Prepare persistent Doop data and authentication secrets";
      before = [ "podman-doop.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "doop-secrets";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      path = [ pkgs.coreutils ];
      script = ''
        install -d -m 0700 -- ${lib.escapeShellArg cfg.dataDir}
        if [ ! -e ${lib.escapeShellArg secretFile} ]; then
          temporary=$(mktemp ${lib.escapeShellArg "${secretFile}.XXXXXX"})
          trap 'rm -f -- "$temporary"' EXIT
          {
            printf 'BETTER_AUTH_SECRET=%s\n' "$(${lib.getExe pkgs.openssl} rand -hex 32)"
            printf 'SECRETS_ENCRYPTION_KEYS=k1:%s\n' "$(${lib.getExe pkgs.openssl} rand -base64 32)"
          } > "$temporary"
          chmod 0600 "$temporary"
          mv -- "$temporary" ${lib.escapeShellArg secretFile}
          trap - EXIT
        fi
        test -s ${lib.escapeShellArg secretFile}
        chmod 0600 ${lib.escapeShellArg secretFile}
      '';
    };

    systemd.services.podman-doop = {
      requires = [ "doop-secrets.service" ] ++ lib.optional buildLocally "doop-image.service";
      after = [
        "doop-secrets.service"
        "network-online.target"
      ]
      ++ lib.optional buildLocally "doop-image.service";
      wants = [ "network-online.target" ];
    };

    systemd.services.doop-image = lib.mkIf buildLocally {
      description = "Build the pinned Doop OCI image from its upstream Dockerfile";
      before = [ "podman-doop.service" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        # Recheck the image on every container start, including after pruning.
        RemainAfterExit = false;
        TimeoutStartSec = "30min";
      };
      script = ''
        if ! ${lib.getExe pkgs.podman} image exists ${lib.escapeShellArg localImage}; then
          ${lib.getExe pkgs.podman} build --format docker \
            --tag ${lib.escapeShellArg localImage} \
            ${lib.escapeShellArg buildContext}
        fi
      '';
    };
  };
}
