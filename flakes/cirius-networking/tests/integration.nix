{ net, pkgs }:
let
  filters = pkgs.writeTextDir "filters.txt" ''
    ||blocked.test^
    ||private.test^
  '';
  libvirtNetwork = pkgs.writeText "adguard-test.xml" ''
    <network>
      <name>adguard-test</name>
      <forward mode='nat'/>
      <bridge name='virbr-test'/>
      <domain name='vm.test' localOnly='yes'/>
      <ip address='192.168.123.1' netmask='255.255.255.0'>
        <dhcp><range start='192.168.123.10' end='192.168.123.20'/></dhcp>
      </ip>
    </network>
  '';
in
pkgs.testers.runNixOSTest {
  name = "cirius-adguardhome";
  nodes = {
    machine = { lib, pkgs, ... }: {
      imports = [ net.nixosModules.default ];
      virtualisation = {
        vlans = [
          1
          2
        ];
        memorySize = 2048;
        cores = 2;
        libvirtd.enable = true;
        podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
        };
      };
      cnix-net.adguardhome.enable = true;
      networking = {
        interfaces.eth0.useDHCP = true;
        interfaces.eth2 = {
          useDHCP = false;
          ipv4.addresses = lib.mkForce [ ];
        };
        bridges.hotspot.interfaces = [ ];
        interfaces.hotspot.ipv4.addresses = [
          {
            address = "10.42.0.1";
            prefixLength = 24;
          }
        ];
        networkmanager = {
          enable = true;
          unmanaged = [
            "interface-name:eth*"
            "interface-name:hotspot"
            "interface-name:vpn-test"
            "interface-name:virbr*"
            "interface-name:podman*"
            "interface-name:veth*"
          ];
        };
      };
      services.adguardhome.settings = {
        dns.upstream_dns = [ "127.0.0.3" ];
        dns.bootstrap_dns = [ "127.0.0.3" ];
        filters = [
          {
            enabled = true;
            id = 1;
            name = "Offline test list";
            url = "http://filters.fixture.test:8081/filters.txt";
          }
        ];
      };
      # Fixture upstream plus simulated WARP/hotspot listeners. No external network is needed.
      services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          listen-address = [
            "127.0.0.3"
            "127.0.2.2"
            "127.0.2.3"
            "10.42.0.1"
          ];
          bind-interfaces = true;
          no-resolv = true;
          address = [
            "/filters.fixture.test/127.0.0.1"
            "/allowed.test/198.51.100.10"
            "/blocked.test/198.51.100.11"
            "/private.test/198.51.100.12"
          ];
        };
      };
      systemd.services.fixture-filter = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3}/bin/python -m http.server 8081 --bind 127.0.0.1 --directory ${filters}";
      };
      systemd.services.adguardhome = {
        requires = [
          "fixture-filter.service"
          "dnsmasq.service"
        ];
        after = [
          "fixture-filter.service"
          "dnsmasq.service"
        ];
      };
      users.users.alice = {
        isNormalUser = true;
        uid = 1000;
      };
      environment.systemPackages = [
        pkgs.dnsutils
        pkgs.curl
        pkgs.jq
        pkgs.libvirt
        pkgs.netcat-openbsd
      ];
    };
    guest = { lib, pkgs, ... }: {
      virtualisation.vlans = [ 2 ];
      networking.interfaces.eth1 = {
        useDHCP = true;
        ipv4.addresses = lib.mkForce [ ];
      };
      networking.dhcpcd.extraConfig = "hostname leased-guest";
      environment.systemPackages = [ pkgs.dnsutils ];
    };
    outsider = { pkgs, ... }: {
      virtualisation.vlans = [ 1 ];
      services.dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          no-resolv = true;
          address = [ "/private.test/198.51.100.12" ];
        };
      };
      networking.firewall = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
      };
      environment.systemPackages = [
        pkgs.dnsutils
        pkgs.curl
      ];
    };
  };
  testScript = ''
    import shlex
    start_all()
    machine.wait_for_unit("adguardhome.service")
    machine.wait_for_unit("systemd-resolved.service")
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:3000/control/status | jq -e .running")

    with subtest("host filtering works without a setup wizard"):
        machine.succeed("stat -c %a /var/lib/private/AdGuardHome | grep -Fx 700")
        machine.wait_until_succeeds("dig @127.0.0.2 blocked.test +time=1 +tries=1 | grep 'status: NXDOMAIN'", timeout=60)
        machine.succeed("dig @127.0.0.2 allowed.test +short | grep -Fx 198.51.100.10")
        machine.succeed("getent ahostsv4 allowed.test | grep 198.51.100.10")
        machine.fail("getent ahostsv4 blocked.test")
        machine.succeed("dig +tcp @127.0.0.2 allowed.test +short | grep -Fx 198.51.100.10")

    with subtest("other DNS listeners coexist and remote exposure stays closed"):
        for address in ["127.0.2.2", "127.0.2.3", "10.42.0.1"]:
            machine.succeed(f"dig @{address} allowed.test +short | grep -Fx 198.51.100.10")
        outsider.wait_for_unit("multi-user.target")
        outsider.fail("curl -fsS --connect-timeout 2 http://machine:3000/control/status")
        outsider.succeed("dig @machine allowed.test +time=1 +tries=1 > /tmp/dns-result 2>&1 || true")
        outsider.fail("grep -q 198.51.100.10 /tmp/dns-result")

    with subtest("specific VPN domains keep their own resolver"):
        outsider.wait_for_unit("dnsmasq.service")
        private_dns = outsider.succeed("ip -4 -o addr show dev eth1 | awk '{print $4}' | cut -d/ -f1").strip()
        machine.succeed(f"resolvectl dns eth1 {private_dns}")
        machine.succeed("resolvectl domain eth1 '~private.test'")
        machine.succeed("resolvectl flush-caches")
        machine.succeed("getent ahostsv4 service.private.test | grep 198.51.100.12")
        machine.fail("getent ahostsv4 blocked.test")

    with subtest("libvirt DHCP, local names, and forwarded DNS survive"):
        machine.wait_for_unit("libvirtd.service")
        machine.succeed("virsh net-create ${libvirtNetwork}")
        machine.succeed("ip link set eth2 master virbr-test; ip link set eth2 up")
        guest.wait_until_succeeds("ip -4 addr show eth1 | grep 192.168.123.")
        guest.wait_until_succeeds("getent ahostsv4 allowed.test | grep 198.51.100.10")
        guest.fail("getent ahostsv4 blocked.test")
        guest.succeed("dig @192.168.123.1 leased-guest.vm.test +short | grep 192.168.123.")

    with subtest("Podman keeps internal names and external DNS"):
        machine.succeed("tar --files-from /dev/null -cf - | podman import - scratchimg")
        mounts = "-v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin"
        machine.succeed(f"podman run -d --name peer {mounts} scratchimg /bin/sleep infinity")
        run = f"podman run --rm {mounts} scratchimg ${pkgs.dnsutils}/bin/dig"
        machine.succeed(f"{run} peer +short | grep '^10[.]88[.]'")
        machine.succeed(f"{run} allowed.test +short | grep -Fx 198.51.100.10")
        machine.succeed(f"{run} blocked.test | grep 'status: NXDOMAIN'")

    with subtest("rootless Podman default networking resolves DNS"):
        machine.wait_until_succeeds("ip -4 route show default | grep via", timeout=60)
        machine.succeed("loginctl enable-linger alice")
        machine.wait_for_unit("user@1000.service")
        def alice(command):
            return "su - alice -c " + shlex.quote("export XDG_RUNTIME_DIR=/run/user/1000; " + command)
        machine.succeed(alice("tar --files-from /dev/null -cf - | podman import - scratchimg"))
        machine.succeed(alice(f"{run} allowed.test +short | grep -Fx 198.51.100.10"))
        machine.succeed(alice(f"{run} blocked.test | grep 'status: NXDOMAIN'"))

    with subtest("restarts retain filtering and resolver routing"):
        machine.succeed("systemctl restart adguardhome NetworkManager")
        machine.wait_until_succeeds("getent ahostsv4 allowed.test | grep 198.51.100.10")
        machine.fail("getent ahostsv4 blocked.test")
        machine.succeed("resolvectl flush-caches")
        machine.succeed("getent ahostsv4 service.private.test | grep 198.51.100.12")
  '';
}
