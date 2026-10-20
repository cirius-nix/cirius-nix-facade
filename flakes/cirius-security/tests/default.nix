{
  inputs,
  pkgs,
  system,
}:
let
  inherit (pkgs) lib;
  home = homeFor pkgs;
  homeFor =
    homePkgs: extra:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = homePkgs;
      modules = [
        inputs.self.homeModules.default
        {
          home.username = "tester";
          home.homeDirectory = "/home/tester";
          home.stateVersion = "26.05";
        }
        extra
      ];
    }).config;
  # Inspect failed assertions before Home Manager's public evaluator throws.
  rawHome =
    extra:
    let
      hmLib = import (inputs.home-manager + "/modules/lib/stdlib-extended.nix") lib;
    in
    (hmLib.evalModules {
      class = "homeManager";
      specialArgs.modulesPath = toString (inputs.home-manager + "/modules");
      modules = [
        inputs.self.homeModules.default
        {
          home.username = "tester";
          home.homeDirectory = "/home/tester";
          home.stateVersion = "26.05";
        }
        extra
      ]
      ++ import (inputs.home-manager + "/modules/modules.nix") {
        inherit pkgs;
        lib = hmLib;
        useNixpkgsModule = false;
      };
    }).config;
  nixos =
    extra:
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        inputs.self.nixosModules.default
        {
          system.stateVersion = "26.05";
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          boot.loader.grub.enable = false;
        }
        extra
      ];
    }).config;
  valid = c: lib.all (a: a.assertion) c.assertions;
  rejects = fragment: c: lib.any (a: !a.assertion && lib.hasInfix fragment a.message) c.assertions;
  disabledHome = home { };
  disabledNixos = nixos { };
  client = home {
    cnix-sec.ssh = {
      enable = true;
      agent.maximumIdentityLifetime = 3600;
      knownHosts = [
        "test.example ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMs3DtqgY2kHWStsXnypC7+FgJ3gHvwD+7WJIB8NqSYb"
      ];
      settings."test.example" = {
        User = "tester";
        IdentitiesOnly = true;
      };
      settings."*".AddKeysToAgent = "confirm";
    };
    cnix-sec.ssh-port-mgt = {
      enable = true;
      settings.profiles.database = {
        enable = true;
        settings = {
          host = "test.example";
          identityFile = "/home/tester/.ssh/tunnel key";
          localForwards = [
            {
              port = 15432;
              destinationPort = 5432;
            }
          ];
          remoteForwards = [
            {
              bindAddress = "::1";
              port = 8080;
              destinationHost = "::1";
              destinationPort = 80;
            }
          ];
        };
      };
    };
  };
  legacy = home {
    cnix-sec.ssh.enable = true;
    cnix-sec.ssh-port-mgt = {
      enable = true;
      settings.profiles = {
        old.enable = true;
        custom = {
          enable = true;
          settings.autoSSHArgs = [
            "-M"
            "0"
            "-N"
            "-L"
            "8080:localhost:80"
            "old-host"
          ];
        };
      };
    };
  };
  darwinTunnel = homeFor inputs.nixpkgs.legacyPackages.aarch64-darwin {
    cnix-sec.ssh.enable = true;
    cnix-sec.ssh-port-mgt = {
      enable = true;
      settings.profiles.mac = {
        enable = true;
        settings.host = "gateway.example";
      };
    };
  };
  dormant = nixos {
    cnix-sec = {
      sshd.settings.PasswordAuthentication = false;
      u2f.services.sudo = "required";
      usbguard.rules = "allow id 1234:5678";
      firewall.allowedTCPPorts = [ 1234 ];
    };
  };
  nativeOverride = nixos {
    cnix-sec.sshd.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "prohibit-password";
    };
  };
  filePolicy = nixos {
    cnix-sec.usbguard = {
      enable = true;
      ruleFile = "/run/usbguard-policy";
    };
  };
  externalAgent = home {
    cnix-sec.ssh.enable = true;
    cnix-sec.ssh.agent.enable = false;
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
  conflictAgent = rawHome {
    cnix-sec.ssh.enable = true;
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
  homeSecrets = home {
    cnix-sec.secret-mgt = {
      enable = true;
      settings.ageSSHKeyPaths = [ "/home/tester/.ssh/id_ed25519" ];
      settings.defaultSecretFormat = "json";
    };
  };
  systemSecrets = nixos {
    cnix-sec.secret-mgt = {
      enable = true;
      settings.ageSSHKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
  keyOverride = home {
    cnix-sec.secret-mgt = {
      enable = true;
      settings.ageKeyFile = "/home/tester/old-key";
      settings.generateAgeKey = true;
    };
    sops.age.keyFile = "/home/tester/actual-key";
  };
  protected = nixos {
    cnix-sec = {
      sshd.enable = true;
      sshd.settings.AllowUsers = [ "tester" ];
      firewall = {
        enable = true;
        interfaces.test0.allowedTCPPorts = [ 22 ];
        allowedUDPPorts = [ 5353 ];
      };
      fail2ban = {
        enable = true;
        settings.maxretry = 4;
      };
      apparmor = {
        enable = true;
        policies.test = {
          state = "complain";
          profile = "profile cnix-test { }";
        };
      };
      u2f = {
        enable = true;
        services.sudo = "required";
        settings = {
          authfile = "/etc/u2f-mappings";
          cue = true;
        };
      };
      usbguard = {
        enable = true;
        rules = "allow id 1234:5678";
      };
    };
  };
  overridden = nixos {
    cnix-sec.sshd = {
      enable = true;
      ports = [ 2222 ];
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = true;
      };
    };
    services.openssh.enable = true; # Mirrors cirius-networking's contribution.
  };
  invalidU2f = nixos { cnix-sec.u2f.enable = true; };
  invalidUsb = nixos { cnix-sec.usbguard.enable = true; };
  conflictingUsb = nixos {
    cnix-sec.usbguard = {
      enable = true;
      rules = "allow id 1234:5678";
      ruleFile = "/run/policy";
    };
  };
  invalidFail2ban = nixos {
    cnix-sec.fail2ban.enable = true;
    networking.firewall.enable = false;
  };
  invalidGeneration = rawHome {
    cnix-sec.secret-mgt = {
      enable = true;
      settings.generateAgeKey = true;
    };
  };
  invalidTunnel = rawHome {
    cnix-sec.ssh.enable = true;
    cnix-sec.ssh-port-mgt = {
      enable = true;
      settings.profiles.bad = {
        enable = true;
        settings.localForwards = [
          {
            port = 80;
            destinationPort = 80;
          }
        ];
      };
    };
  };
  command = lib.concatStringsSep " " client.systemd.user.services.cnix-sec-ssh-port-mgt-database.Service.ExecStart;
  sshConfig = client.home.file.".ssh/config".text;
  checks = {
    disabled-home =
      valid disabledHome
      && !disabledHome.services.ssh-agent.enable
      && disabledHome.sops.age.keyFile == null;
    disabled-nixos =
      valid disabledNixos
      && !disabledNixos.services.openssh.enable
      && !disabledNixos.services.fail2ban.enable
      && !disabledNixos.security.apparmor.enable
      && !disabledNixos.services.usbguard.enable
      && disabledNixos.cnix-sec.secure-store.settings.luksDevicePath == null;
    ssh-client =
      valid client
      && client.services.ssh-agent.defaultMaximumIdentityLifetime == 3600
      && lib.hasInfix "AddKeysToAgent confirm" sshConfig
      && lib.hasInfix "cnix_known_hosts" sshConfig
      && lib.hasInfix "test.example ssh-ed25519" client.home.file.".ssh/cnix_known_hosts".text;
    typed-tunnel = lib.all (s: lib.hasInfix s command) [
      "BatchMode=yes"
      "ServerAliveInterval=30"
      "ExitOnForwardFailure=yes"
      "127.0.0.1:15432:127.0.0.1:5432"
      "[::1]:8080:[::1]:80"
      "tunnel key"
      "test.example"
    ];
    legacy-tunnel =
      valid legacy
      &&
        legacy.cnix-sec.ssh-port-mgt.settings.profiles.old.settings.autoSSHArgs == [
          "-M"
          "0"
          "-N"
          "cnix-sec-ssh-port-mgt-old"
        ]
      &&
        lib.last legacy.cnix-sec.ssh-port-mgt.settings.profiles.custom.settings.autoSSHArgs == "old-host";
    darwin-tunnel =
      valid darwinTunnel
      && builtins.isList darwinTunnel.launchd.agents.cnix-sec-ssh-port-mgt-mac.config.ProgramArguments
      &&
        lib.last darwinTunnel.launchd.agents.cnix-sec-ssh-port-mgt-mac.config.ProgramArguments
        == "gateway.example"
      &&
        darwinTunnel.launchd.agents.cnix-sec-ssh-port-mgt-mac.config.EnvironmentVariables.AUTOSSH_GATETIME
        == "0";
    dormant-settings =
      valid dormant
      && !dormant.services.openssh.enable
      && dormant.services.openssh.settings.PasswordAuthentication
      && !dormant.security.pam.services.sudo.u2f.enable
      && !dormant.services.usbguard.enable
      && !(lib.elem 1234 dormant.networking.firewall.allowedTCPPorts);
    native-overrides =
      valid nativeOverride
      && nativeOverride.services.openssh.settings.PasswordAuthentication
      && nativeOverride.services.openssh.settings.PermitRootLogin == "prohibit-password";
    usb-runtime-policy =
      valid filePolicy
      && filePolicy.services.usbguard.rules == null
      && filePolicy.services.usbguard.ruleFile == "/run/usbguard-policy";
    external-agent = valid externalAgent && !externalAgent.services.ssh-agent.enable;
    agent-conflict = rejects "GnuPG SSH agent" conflictAgent;
    ssh-identities =
      valid homeSecrets
      && homeSecrets.sops.age.keyFile == null
      && homeSecrets.sops.defaultSopsFormat == "json"
      && homeSecrets.sops.age.sshKeyPaths == [ "/home/tester/.ssh/id_ed25519" ]
      && valid systemSecrets
      && systemSecrets.sops.age.sshKeyPaths == [ "/etc/ssh/ssh_host_ed25519_key" ];
    key-override =
      valid keyOverride
      && keyOverride.sops.age.keyFile == "/home/tester/actual-key"
      && keyOverride.sops.age.generateKey;
    host-protection =
      valid protected
      && protected.services.openssh.enable
      && !protected.services.openssh.openFirewall
      && !protected.services.openssh.settings.PasswordAuthentication
      && protected.services.openssh.settings.PermitRootLogin == "no"
      && !(lib.elem 22 protected.networking.firewall.allowedTCPPorts)
      && lib.elem 22 protected.networking.firewall.interfaces.test0.allowedTCPPorts
      && protected.services.fail2ban.maxretry == 4
      && protected.services.openssh.settings.LogLevel == "VERBOSE"
      && protected.security.apparmor.policies.test.state == "complain"
      && protected.security.pam.services.sudo.u2f.enable
      && protected.security.pam.services.sudo.u2f.control == "required"
      && !protected.security.pam.services.login.u2f.enable
      && protected.services.usbguard.rules == "allow id 1234:5678";
    server-overrides =
      valid overridden
      && overridden.services.openssh.settings.PasswordAuthentication
      && overridden.services.openssh.settings.KbdInteractiveAuthentication
      && overridden.services.openssh.ports == [ 2222 ];
    invalid-u2f = rejects "u2f.services" invalidU2f;
    invalid-usb =
      rejects "USBGuard requires exactly one" invalidUsb
      && rejects "USBGuard requires exactly one" conflictingUsb;
    invalid-firewall = rejects "Fail2ban requires a firewall" invalidFail2ban;
    invalid-key-generation = rejects "generateAgeKey requires" invalidGeneration;
    invalid-tunnel = rejects "requires settings.host" invalidTunnel;
  };
in
{
  modules =
    assert lib.assertMsg (lib.all (x: x) (lib.attrValues checks))
      "cirius-security checks failed: ${
        lib.concatStringsSep ", " (lib.attrNames (lib.filterAttrs (_: passed: !passed) checks))
      }";
    pkgs.runCommand "cirius-security-modules" { } ''
      echo '${builtins.toJSON (lib.attrNames checks)}' > "$out"
    '';
  ssh-config =
    pkgs.runCommand "cirius-security-ssh-config" { nativeBuildInputs = [ pkgs.openssh ]; }
      ''
        ssh -G -F ${pkgs.writeText "cnix-ssh-config" sshConfig} test.example > "$out"
        grep -q '^addkeystoagent confirm$' "$out"
        grep -q '^identitiesonly yes$' "$out"
        grep -q '^user tester$' "$out"
        grep -q '^userknownhostsfile .*cnix_known_hosts' "$out"
      '';
  host-protection = import ./host-protection.nix { inherit inputs pkgs; };
}
