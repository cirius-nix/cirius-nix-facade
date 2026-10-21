{
  system ? builtins.currentSystem,
  inputs ?
    let
      security = builtins.getFlake (toString ./..);
    in
    {
      self = security;
      inherit (security.inputs) nixpkgs;
      # A development-only dependency, pinned independently of consumers.
      home-manager = builtins.getFlake "github:nix-community/home-manager/5bf02bcfede52ca95f693069ac28ace376942c05";
    },
  pkgs ? inputs.nixpkgs.legacyPackages.${system},
}:
let
  inherit (pkgs) lib;
  evalSystem =
    extra:
    inputs.nixpkgs.lib.nixosSystem {
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
    };
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
  home = homeFor pkgs;
  valid = c: lib.all (a: a.assertion) c.assertions;
  disabled = (evalSystem { }).config;
  # Each retained concern must evaluate with its enable flag alone.
  defaults = lib.genAttrs [ "sshd" "firewall" "fail2ban" "secret-mgt" ] (
    name: (evalSystem { cnix-sec.${name}.enable = true; }).config
  );
  native =
    (evalSystem {
      cnix-sec = {
        sshd.enable = true;
        firewall.enable = true;
        fail2ban.enable = true;
      };
      services.openssh = {
        ports = [ 2222 ];
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      networking.firewall.interfaces.eth1.allowedTCPPorts = [ 2222 ];
      services.fail2ban.maxretry = 5;
    }).config;
  client = home {
    cnix-sec = {
      ssh.enable = true;
      secret-mgt.enable = true;
      ssh-port-mgt.enable = true;
    };
  };
  homeDefaults = lib.genAttrs [ "ssh" "secret-mgt" "ssh-port-mgt" ] (
    name: home { cnix-sec.${name}.enable = true; }
  );
  externalAgent = home {
    cnix-sec.ssh.enable = true;
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
    };
  };
  nativeClient = home {
    cnix-sec = {
      ssh.enable = true;
      secret-mgt.enable = true;
    };
    services.ssh-agent.defaultMaximumIdentityLifetime = 3600;
    programs.ssh.settings."*".AddKeysToAgent = "confirm";
    programs.ssh.settings."test.example" = {
      User = "tester";
      IdentitiesOnly = true;
    };
    sops.age.sshKeyPaths = [ "/home/tester/.ssh/id_ed25519" ];
    sops.defaultSopsFormat = "json";
  };
  legacySecret = home {
    cnix-sec.secret-mgt = {
      enable = true;
      settings.ageKeyFile = "/home/tester/old-key";
    };
  };
  tunnelConfig = {
    cnix-sec.ssh.enable = true;
    cnix-sec.ssh-port-mgt = {
      enable = true;
      settings.profiles = {
        database.enable = true;
        custom = {
          enable = true;
          settings.autoSSHArgs = [
            "-M"
            "0"
            "-N"
            "legacy-host"
          ];
        };
      };
    };
    programs.ssh.settings.cnix-sec-ssh-port-mgt-database = {
      HostName = "gateway.example";
      LocalForward = [ "127.0.0.1:15432 127.0.0.1:5432" ];
    };
  };
  tunnel = home tunnelConfig;
  darwin = homeFor inputs.nixpkgs.legacyPackages.aarch64-darwin tunnelConfig;
  checks = {
    opt-in = valid disabled && !disabled.services.openssh.enable && !disabled.services.fail2ban.enable;
    enable-only =
      lib.all valid (lib.attrValues defaults)
      && lib.all valid (lib.attrValues homeDefaults)
      && valid client;
    ssh-reachable =
      defaults.sshd.services.openssh.enable
      && defaults.sshd.services.openssh.openFirewall
      && lib.elem 22 defaults.sshd.networking.firewall.allowedTCPPorts;
    tunnel-dependency = homeDefaults.ssh-port-mgt.cnix-sec.ssh.enable;
    firewall-default = defaults.firewall.networking.firewall.enable;
    fail2ban-default =
      defaults.fail2ban.services.fail2ban.enable
      && defaults.fail2ban.networking.firewall.enable
      && !defaults.fail2ban.services.openssh.enable;
    small-api =
      lib.all (name: builtins.attrNames (evalSystem { }).options.cnix-sec.${name} == [ "enable" ])
        [
          "sshd"
          "firewall"
          "fail2ban"
        ];
    native-overrides =
      valid native
      && native.services.openssh.ports == [ 2222 ]
      && !native.services.openssh.openFirewall
      && !native.services.openssh.settings.PasswordAuthentication
      && native.services.fail2ban.maxretry == 5
      && lib.elem 2222 native.networking.firewall.interfaces.eth1.allowedTCPPorts;
    external-agent = valid externalAgent && !externalAgent.services.ssh-agent.enable;
    home-overrides =
      valid nativeClient
      && nativeClient.services.ssh-agent.defaultMaximumIdentityLifetime == 3600
      && nativeClient.sops.defaultSopsFormat == "json"
      && nativeClient.sops.age.sshKeyPaths == [ "/home/tester/.ssh/id_ed25519" ];
    legacy-secret = valid legacySecret && legacySecret.sops.age.keyFile == "/home/tester/old-key";
    reconnect-defaults =
      valid tunnel
      && lib.elem "ServerAliveInterval=30" tunnel.cnix-sec.ssh-port-mgt.settings.profiles.database.settings.autoSSHArgs
      &&
        lib.last tunnel.cnix-sec.ssh-port-mgt.settings.profiles.database.settings.autoSSHArgs
        == "cnix-sec-ssh-port-mgt-database"
      &&
        tunnel.cnix-sec.ssh-port-mgt.settings.profiles.custom.settings.autoSSHArgs == [
          "-M"
          "0"
          "-N"
          "legacy-host"
        ];
    darwin-tunnel =
      valid darwin
      && builtins.isList darwin.launchd.agents.cnix-sec-ssh-port-mgt-database.config.ProgramArguments;
  };
in
{
  modules =
    assert lib.assertMsg (lib.all (x: x) (lib.attrValues checks))
      "cirius-security checks failed: ${
        lib.concatStringsSep ", " (lib.attrNames (lib.filterAttrs (_: passed: !passed) checks))
      }";
    pkgs.runCommand "cirius-security-modules" { }
      ''echo '${builtins.toJSON (lib.attrNames checks)}' > "$out"'';
  ssh-config =
    pkgs.runCommand "cirius-security-ssh-config" { nativeBuildInputs = [ pkgs.openssh ]; }
      ''
        ssh -G -F ${
          pkgs.writeText "cnix-ssh-config" nativeClient.home.file.".ssh/config".text
        } test.example > "$out"
        grep -q '^addkeystoagent confirm$' "$out"
        grep -q '^identitiesonly yes$' "$out"
        ssh -G -F ${
          pkgs.writeText "cnix-tunnel-config" tunnel.home.file.".ssh/config".text
        } cnix-sec-ssh-port-mgt-database > tunnel-config
        grep -q '^hostname gateway.example$' tunnel-config
        grep -q '^localforward .*15432 .*5432$' tunnel-config
      '';
  host-protection = import ./host-protection.nix { inherit inputs pkgs; };
}
