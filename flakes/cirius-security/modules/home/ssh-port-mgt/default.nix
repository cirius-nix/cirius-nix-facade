{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  forwardType = lib.types.submodule {
    options = {
      bindAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address on which the forwarding listener binds.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port on which the forwarding listener binds.";
      };
      destinationHost = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Destination host as seen from the other end of the SSH connection.";
      };
      destinationPort = lib.mkOption {
        type = lib.types.port;
        description = "Destination TCP port.";
      };
    };
  };
  address = host: if lib.hasInfix ":" host && !(lib.hasPrefix "[" host) then "[${host}]" else host;
  forward =
    f:
    "${address f.bindAddress}:${toString f.port}:${address f.destinationHost}:${toString f.destinationPort}";
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

              host = lib.mkOption {
                type = with lib.types; nullOr (strMatching "[^-[:space:]][^[:space:]]*");
                default = null;
                description = "SSH host alias for typed tunnel arguments. Null preserves the legacy command arguments.";
              };
              identityFile = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = "Runtime path to the private key. Keep private keys outside the Nix store.";
              };
              localForwards = lib.mkOption {
                type = lib.types.listOf forwardType;
                default = [ ];
                description = "Forward listeners on this machine to destinations reached by the SSH server.";
              };
              remoteForwards = lib.mkOption {
                type = lib.types.listOf forwardType;
                default = [ ];
                description = "Forward listeners on the SSH server to destinations reached by this machine.";
              };
              serverAliveInterval = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 30;
                description = "Seconds between SSH keepalive messages in typed mode.";
              };
              serverAliveCountMax = lib.mkOption {
                type = lib.types.ints.positive;
                default = 3;
                description = "Number of unanswered keepalives before disconnecting in typed mode.";
              };
              exitOnForwardFailure = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Exit if a forwarding listener cannot be established in typed mode.";
              };
              autoSSHArgs = lib.mkOption {
                type = with lib.types; listOf str;
                default =
                  let
                    s = profileInputs.config.settings;
                  in
                  [
                    "-M"
                    "0"
                    "-N"
                  ]
                  ++ lib.optionals (s.host != null) (
                    [
                      "-o"
                      "BatchMode=yes"
                      "-o"
                      "ServerAliveInterval=${toString s.serverAliveInterval}"
                      "-o"
                      "ServerAliveCountMax=${toString s.serverAliveCountMax}"
                      "-o"
                      "ExitOnForwardFailure=${if s.exitOnForwardFailure then "yes" else "no"}"
                    ]
                    ++ lib.optionals (s.identityFile != null) [
                      "-i"
                      s.identityFile
                      "-o"
                      "IdentitiesOnly=yes"
                    ]
                    ++ lib.concatMap (f: [
                      "-L"
                      (forward f)
                    ]) s.localForwards
                    ++ lib.concatMap (f: [
                      "-R"
                      (forward f)
                    ]) s.remoteForwards
                  )
                  ++ [ (if s.host == null then profileName else s.host) ];
                description = "Complete autossh argument list. An explicit value replaces generated typed arguments and preserves the legacy API. Typed mode uses noninteractive key authentication; provision known host keys first.";
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
      inherit (config.${namespace}) ssh ssh-port-mgt;
      profiles = lib.filterAttrs (_: p: p.enable) ssh-port-mgt.settings.profiles;
      profileServices = lib.mapAttrs' (_: p: p.build.services) profiles;
    in
    lib.mkMerge [
      (lib.mkIf (ssh-port-mgt.enable) {
        assertions =
          (lib.mapAttrsToList (name: p: {
            assertion =
              p.settings.host != null
              || (
                p.settings.identityFile == null
                && p.settings.localForwards == [ ]
                && p.settings.remoteForwards == [ ]
              );
            message = "cnix-sec: tunnel ${name} requires settings.host when using typed identity or forwarding options.";
          }) profiles)
          ++ [
            {
              assertion = ssh.enable == true;
              message = "SSH port management requires SSH to be enabled.";
            }
          ];

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
