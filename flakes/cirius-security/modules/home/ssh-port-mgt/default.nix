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
        profileInputs:
        let
          profileName = lib.concatStringsSep "-" [
            namespace
            "ssh-port-mgt"
            profileInputs.name
          ];
        in
        {
          options = {
            enable = mkOption {
              type = bool;
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
                  profileName
                ];
                description = "Additional arguments to pass to the SSH command for this profile.";
              };
            };

            build.services = {
              name = lib.mkOption {
                readOnly = true;
                type = lib.types.str;
                default = profileName;
                description = "The name of the built SSH port management profile.";
              };
              value = lib.mkOption {
                type = with lib.types; attrsOf anything;
                description = "The built SSH port management profile.";
              };
            };
          };

          config =
            let
              inherit (profileInputs.settings) passwordFile autoSSHArgs;

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
            {
              build.services = {
                name = profileName;
                value = {
                  Unit = {
                    description = "SSH port management profile for ${profileInputs.name}.";
                    Wants = [ "network-online.target" ];
                    After = [ "network-online.target" ];
                    Services = {
                      Environment = [ "AUTOSSH_GATETIME=0" ];
                      ExecStart = execStartCommand;
                      Restart = "always";
                      RestartSec = "10s";
                    };
                    Install.WantedBy = [ "default.target" ];
                  };
                };
              };
            };
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
      profileServices = lib.mapAttrs (_: p: p.build.services) profiles;
    in
    lib.mkMerge [
      (lib.mkIf (ssh-port-mgt.enable) {
        home.packages = with pkgs; [
          autossh
          sshpass
        ];
        systemd.user.services = profileServices;
      })
    ];
}
