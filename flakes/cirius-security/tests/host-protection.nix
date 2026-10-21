{ inputs, pkgs }:
let
  keys = import (inputs.nixpkgs + "/nixos/tests/ssh-keys.nix") pkgs;
in
pkgs.testers.runNixOSTest {
  name = "cirius-security-host-protection";
  nodes = {
    server = { pkgs, ... }: {
      imports = [ inputs.self.nixosModules.default ];
      cnix-sec = {
        sshd.enable = true;
        firewall.enable = true;
        fail2ban.enable = true;
      };
      users.users.tester = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [ keys.snakeOilEd25519PublicKey ];
      };
      environment.systemPackages = [
        pkgs.netcat-openbsd
      ];
      # A real listener behind the firewall, so a denied connection proves filtering.
      systemd.services.closed-port = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8080,reuseaddr,fork EXEC:${pkgs.coreutils}/bin/cat";
      };
    };
    client = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.openssh
        pkgs.netcat-openbsd
      ];
    };
  };
  testScript = ''
    start_all()
    server.wait_for_unit("sshd.service")
    server.wait_for_unit("fail2ban.service")
    server.wait_for_open_port(8080)
    client.wait_for_unit("multi-user.target")

    client.succeed("install -m 600 ${keys.snakeOilEd25519PrivateKey} /tmp/test-key")
    ssh = "ssh -4 -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -i /tmp/test-key"
    client.succeed(f"{ssh} tester@server true")
    client.fail(f"{ssh} root@server true")
    # The listener exists, but its port is not allowed on eth1.
    server.succeed("nc -z -w 2 127.0.0.1 8080")
    client.fail("nc -4 -z -w 2 server 8080")

    client_ip = client.succeed("ip -4 -o addr show dev eth1 | awk '{print $4}' | cut -d/ -f1").strip()
    server.succeed(f"fail2ban-client set sshd unbanip {client_ip}")
    for _ in range(4):
        client.execute(f"{ssh} -o PreferredAuthentications=none invalid-user@server true")
    server.wait_until_succeeds(f"test 1 -eq $(fail2ban-client get sshd banned {client_ip})")
    client.fail("nc -4 -z -w 2 server 22")
    server.succeed(f"fail2ban-client set sshd unbanip {client_ip}")
    client.wait_until_succeeds(f"{ssh} tester@server true")
  '';
}
