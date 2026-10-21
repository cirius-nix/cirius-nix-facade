{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  profileModuleTypes =
    with lib.types;
    attrsOf (
      submodule (
        { name, ... }@profileInputs:
        let
          profileName = lib.concatStringsSep "-" [
            namespace
            "ssh-port-mgt"
            name
          ];
        in
        {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable this SSH port management profile.";
            };
            settings = {
              passwordFile = lib.mkOption {
                type = with lib.types; nullOr path;
                default = null;
                description = "Path to the password file for this profile.";
              };

              autoSSHArgs = lib.mkOption {
                type = with lib.types; listOf str;
                default = [
                  "-M"
                  "0"
                  "-N"
                  "-o"
                  "ServerAliveInterval=30"
                  "-o"
                  "ServerAliveCountMax=3"
                  "-o"
                  "ExitOnForwardFailure=yes"
                  profileName
                ];
                description = "Complete autossh arguments. Override only for advanced connections; ordinary profiles use the generated SSH alias and reconnect defaults.";
              };
            };

            build.services = {
              name = lib.mkOption {
                type = lib.types.str;
                default = profileName;
                description = "The name of the built SSH port management profile.";
              };
              value = lib.mkOption {
                type = with lib.types; nullOr (attrsOf anything);
                default = null;
                description = "The built SSH port management profile.";
              };
            };
          };

          config =
            let
              inherit (profileInputs.config.settings) passwordFile autoSSHArgs;

              # executable commands
              sshPassCommand =
                if passwordFile != null then
                  [
                    (lib.getExe pkgs.sshpass)
                    "-f"
                    (toString passwordFile)
                  ]
                else
                  [ ];
              autoSSHCommand = [ (lib.getExe pkgs.autossh) ] ++ autoSSHArgs;
              execStartCommand = lib.escapeShellArgs (sshPassCommand ++ autoSSHCommand);
            in
            lib.mkMerge [
              (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
                build.services = {
                  name = profileName;
                  value = {
                    Unit = {
                      Description = "SSH port management profile for ${name}.";
                      Wants = [ "network-online.target" ];
                      After = [ "network-online.target" ];
                    };
                    Service = {
                      Environment = [ "AUTOSSH_GATETIME=0" ];
                      ExecStart = execStartCommand;
                      Restart = "always";
                      RestartSec = "10s";
                    };
                    Install.WantedBy = [ "default.target" ];
                  };
                };
              })

              (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
                build.services = {
                  name = profileName;
                  value = {
                    enable = true;
                    config = {
                      Label = profileName;
                      ProgramArguments = sshPassCommand ++ autoSSHCommand;
                      EnvironmentVariables.AUTOSSH_GATETIME = "0";
                      RunAtLoad = true;
                      KeepAlive = true;
                    };
                  };
                };
              })
            ];
        }
      )
    );
in
{
  options.${namespace}.ssh-port-mgt = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable SSH port management.";
    };
    settings = {
      profiles = lib.mkOption {
        type = profileModuleTypes;
        default = { };
        description = "SSH port management profiles.";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}) ssh-port-mgt;
      profiles = lib.filterAttrs (_: p: p.enable) ssh-port-mgt.settings.profiles;
      profileServices = lib.mapAttrs' (_: p: p.build.services) profiles;
    in
    lib.mkMerge [
      (lib.mkIf (ssh-port-mgt.enable) {
        ${namespace}.ssh.enable = lib.mkDefault true;

        home.packages = with pkgs; [
          autossh
          sshpass
        ];
      })

      # Linux specific configuration
      (lib.mkIf (ssh-port-mgt.enable && pkgs.stdenv.hostPlatform.isLinux) ({
        systemd.user.services = profileServices;
      }))

      # Darwin specific configuration
      (lib.mkIf (ssh-port-mgt.enable && pkgs.stdenv.hostPlatform.isDarwin) ({
        launchd.agents = profileServices;
      }))
    ];
}
