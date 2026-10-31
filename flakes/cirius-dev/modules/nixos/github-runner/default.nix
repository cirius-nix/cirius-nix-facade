{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.github-runner;

  runnerModule = {
    options = {
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "https://github.com/cirius-nix/cirius-nix-facade";
        description = ''
          Repository or organisation URL the runner registers with. A repository
          URL limits it to that repository; an organisation URL shares it across
          every repository in the organisation.
        '';
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          File containing a fine-grained personal access token, a classic PAT, or
          a runner registration token. Prefer a PAT (or `githubApp`) stored
          through secret management: registration tokens expire after an hour,
          which breaks later re-registration.
        '';
      };

      githubApp = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              id = lib.mkOption {
                type = lib.types.int;
                description = "The GitHub App's numeric ID (not the client ID).";
              };
              login = lib.mkOption {
                type = lib.types.str;
                description = "Organisation or user the App is installed on.";
              };
              privateKeyFile = lib.mkOption {
                type = lib.types.path;
                description = "PEM-encoded private key for the App.";
              };
            };
          }
        );
        default = null;
        description = ''
          Authenticate with a GitHub App installation instead of a token file.
          Exactly one of `tokenFile` and `githubApp` must be set.
        '';
      };

      extraLabels = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "nixos" "x86_64-linux" ];
        description = "Additional labels advertised by the runner.";
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "with pkgs; [ nodejs pnpm ]";
        description = "Packages added to the runner's PATH.";
      };

      ephemeral = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Register a fresh runner for every job and remove it afterwards. Needs
          a PAT or GitHub App credential, not a short-lived registration token.
        '';
      };

      workDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/var/lib/github-runner/nixos/work";
        description = ''
          Directory available as `$GITHUB_WORKSPACE` and used for repository
          checkouts. Defaults to the systemd runtime directory, which is tmpfs
          and is wiped on boot. The runner cleans this directory on every
          service start, so use a dedicated subdirectory per runner.

          The directory must already exist and be writable by the service user.
          With the default dynamic user that means either running the runner as
          a static user, or having systemd create the directory through
          `StateDirectory`.
        '';
      };
    };
  };
in
{
  options.${namespace}.github-runner = {
    enable = lib.mkEnableOption "self-hosted GitHub Actions runners";

    runners = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule runnerModule);
      default = { };
      description = ''
        Runners keyed by registration name. Each entry becomes one systemd
        service `github-runner-<name>` with its own state, logs, and work
        directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.concatLists (
      lib.mapAttrsToList (
        name: runner: [
          {
            assertion = (runner.tokenFile == null) != (runner.githubApp == null);
            message = "${namespace}.github-runner.runners.${name}: exactly one of `tokenFile` and `githubApp` must be set.";
          }
          {
            assertion = runner.url != null;
            message = "${namespace}.github-runner.runners.${name}: `url` must be set.";
          }
        ]
      ) cfg.runners
    );

    services.github-runners = lib.mapAttrs (_: runner: {
      enable = true;
      inherit (runner)
        url
        tokenFile
        githubApp
        extraLabels
        extraPackages
        ephemeral
        workDir
        ;
    }) cfg.runners;
  };
}
