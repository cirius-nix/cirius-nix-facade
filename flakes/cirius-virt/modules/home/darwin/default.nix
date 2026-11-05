{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.container;
  apps = cfg.containers;
  # The Docker client sends this source to the Linux VM as a build context.
  # No /nix/store bind mount inside Docker Desktop is needed.
  doopSource = pkgs.fetchFromGitHub {
    owner = "kgoedecke";
    repo = "doop";
    rev = "v0.13.0";
    hash = "sha256-kQiB/+89z2wSme8GEL+dR+De5A/AZzKeHnJsZtok1ck=";
  };
  compose = import ./_compose.nix { inherit lib cfg doopSource; };
  composeFile = (pkgs.formats.yaml { }).generate "cirius-compose.yaml" compose;
  runner = pkgs.writeShellApplication {
    name = "cnix-containers";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.openssl
    ];
    text = ''
      export PATH=${lib.escapeShellArg (builtins.dirOf cfg.dockerCommand)}:"$PATH"
      docker=${lib.escapeShellArg cfg.dockerCommand}
      context=${lib.escapeShellArg cfg.dockerContext}
      state=${lib.escapeShellArg cfg.dataDir}
      compose_file=${lib.escapeShellArg (toString composeFile)}
      ${builtins.readFile ./_runner.sh}
    '';
  };
  appOptions = defaultPort: {
    enable = lib.mkEnableOption "this local container application";
    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:${toString defaultPort}";
      description = "Published loopback address and port on the Mac.";
    };
  };
in
{
  options.${namespace}.container = {
    enable = lib.mkEnableOption "local Docker Desktop applications";
    dockerCommand = lib.mkOption {
      type = lib.types.str;
      default = "/Applications/Docker.app/Contents/Resources/bin/docker";
      description = "Existing Docker Desktop CLI; this module does not install Docker.";
    };
    dockerContext = lib.mkOption {
      type = lib.types.str;
      default = "desktop-linux";
      description = "Docker Desktop context used explicitly for every command.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.dataHome}/cirius-containers";
      description = "Private runtime env directory. Application data uses persistent Docker named volumes.";
    };
    containers = {
      doop = appOptions 4400 // {
        publicUri = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:4400";
          description = "Browser origin for Doop authentication.";
        };
      };
      penpot = appOptions 9001 // {
        publicUri = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:9001";
          description = "Browser origin for Penpot.";
        };
        version = lib.mkOption {
          type = lib.types.str;
          default = "2.18.6";
          description = "One release for all five Penpot images.";
        };
      };
      dockhand = appOptions 2000 // {
        image = lib.mkOption {
          type = lib.types.str;
          default = "docker.io/fnsys/dockhand:5a3b1e8d";
          description = "ARM64-capable image; baseline images target x86 CPUs.";
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
        message = "The Docker Desktop module targets Apple Silicon macOS.";
      }
      {
        assertion = apps.doop.enable || apps.penpot.enable || apps.dockhand.enable;
        message = "Enable at least one cnix-virt.container.containers application.";
      }
      {
        assertion = lib.hasPrefix "${config.home.homeDirectory}/" cfg.dataDir;
        message = "Container runtime env files must be under this user's home directory.";
      }
    ];
    home.packages = [ runner ];
    xdg.configFile."cirius-containers/compose.yaml".source = composeFile;
  };
}
