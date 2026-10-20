{
  inputs,
  config,
  lib,
  namespace,
  pkgs,
  options,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports =
    (with inputs; [
      sops-nix.homeManagerModules.sops
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);

  options.${namespace} = {
    ssh = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable SSH configuration.";
      };

      additionalConfigPaths = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional SSH configuration files to include.";
      };

      agent = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start the OpenSSH agent when SSH is enabled. Disable this for an external agent.";
        };
        maximumIdentityLifetime = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = 28800;
          description = "Default key lifetime in seconds. Null removes the time limit.";
        };
      };

      settings = lib.mkOption {
        type = options.programs.ssh.settings.type;
        default = { };
        description = "SSH Host and Match blocks, with the Home Manager settings type and ordering.";
      };

      knownHosts = lib.mkOption {
        type = lib.types.listOf lib.types.singleLineStr;
        default = [ ];
        description = "Public known_hosts entries. Stored in a separate managed file alongside the writable known_hosts file.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) ssh;
    in
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          sops
          age
        ];
      }

      (lib.mkIf ssh.enable {
        assertions = [
          {
            assertion =
              !(
                ssh.agent.enable && config.services.gpg-agent.enable && config.services.gpg-agent.enableSshSupport
              );
            message = "cnix-sec: disable ssh.agent.enable when using the GnuPG SSH agent.";
          }
        ];
        services.ssh-agent = {
          enable = lib.mkDefault (
            ssh.agent.enable
            && !(config.services.gpg-agent.enable && config.services.gpg-agent.enableSshSupport)
          );
          defaultMaximumIdentityLifetime = lib.mkDefault ssh.agent.maximumIdentityLifetime;
        };

        home.file.".ssh/cnix_known_hosts" = lib.mkIf (ssh.knownHosts != [ ]) {
          text = lib.concatStringsSep "\n" ssh.knownHosts + "\n";
        };

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = lib.mkMerge [
            { "*".AddKeysToAgent = lib.mkDefault "yes"; }
            (lib.mkIf (ssh.knownHosts != [ ]) {
              "*".UserKnownHostsFile = lib.mkDefault "~/.ssh/known_hosts ~/.ssh/cnix_known_hosts";
            })
            ssh.settings
          ];
          extraConfig = lib.concatMapStringsSep "\n" (x: "Include ${x}") ssh.additionalConfigPaths;
        };
      })
    ];
}
