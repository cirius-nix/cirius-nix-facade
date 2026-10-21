{
  system ? builtins.currentSystem,
  net ? builtins.getFlake ("path:" + toString ./..),
  virt ? builtins.getFlake ("path:" + toString ../../cirius-virt),
  pkgs ? net.inputs.nixpkgs.legacyPackages.${system},
}:
let
  inherit (pkgs) lib;
  eval =
    extra:
    net.inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        net.nixosModules.default
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
  valid = c: lib.all (a: a.assertion) c.assertions;
  disabled = (eval { }).config;
  defaults = (eval { cnix-net.adguardhome.enable = true; }).config;
  serviceOnly =
    (eval {
      cnix-net.adguardhome = {
        enable = true;
        useAsSystemResolver = false;
      };
    }).config;
  externalResolver =
    (eval {
      cnix-net.adguardhome = {
        enable = true;
        useAsSystemResolver = false;
      };
      services.resolved = {
        enable = true;
        settings.Resolve.DNS = [ "192.0.2.53" ];
      };
    }).config;
  native =
    (eval {
      cnix-net.adguardhome.enable = true;
      services.adguardhome.settings = {
        http.address = "127.0.0.1:3333";
        dns.bind_hosts = [ "127.0.0.4" ];
        dns.port = 5353;
        dns.upstream_dns = [ "192.0.2.53" ];
        filters = [ ];
      };
    }).config;
  combined =
    (eval {
      imports = [ virt.nixosModules.default ];
      cnix-net = {
        enable = true;
        adguardhome.enable = true;
      };
      cnix-virt.container.enable = true;
    }).config;
  checks = {
    disabled =
      valid disabled
      && !disabled.services.adguardhome.enable
      && !disabled.services.openssh.enable
      && !disabled.services.resolved.enable;
    enable-only =
      valid defaults
      && defaults.services.adguardhome.enable
      && defaults.services.resolved.enable
      && !defaults.services.openssh.enable
      && !defaults.services.caddy.enable
      && !defaults.services.tailscale.enable;
    api =
      builtins.attrNames (eval { }).options.cnix-net.adguardhome == [
        "enable"
        "useAsSystemResolver"
      ];
    local =
      defaults.services.adguardhome.settings.dns.bind_hosts == [ "127.0.0.2" ]
      && defaults.services.adguardhome.settings.http.address == "127.0.0.1:3000"
      && !defaults.services.adguardhome.openFirewall
      && !defaults.services.adguardhome.allowDHCP
      && !defaults.services.adguardhome.settings.dhcp.enabled;
    resolver =
      defaults.services.resolved.settings.Resolve.DNS == [ "127.0.0.2" ]
      && defaults.services.resolved.settings.Resolve.Domains == [ "~." ]
      && defaults.networking.networkmanager.dns == "systemd-resolved";
    protection =
      !defaults.services.adguardhome.mutableSettings
      && defaults.services.adguardhome.settings.filtering.protection_enabled
      && defaults.services.adguardhome.settings.filtering.filtering_enabled
      && (builtins.head defaults.services.adguardhome.settings.filters).enabled
      && defaults.services.adguardhome.settings.dns.bootstrap_dns != [ ]
      && !defaults.services.adguardhome.settings.dns.use_private_ptr_resolvers;
    service-only =
      valid serviceOnly
      && serviceOnly.services.adguardhome.enable
      && !serviceOnly.services.resolved.enable;
    external-resolver =
      valid externalResolver
      && externalResolver.services.resolved.settings.Resolve.DNS == [ "192.0.2.53" ];
    native-overrides =
      valid native
      && native.services.adguardhome.settings.dns.upstream_dns == [ "192.0.2.53" ]
      && native.services.resolved.settings.Resolve.DNS == [ "127.0.0.4:5353" ]
      && native.services.adguardhome.settings.filters == [ ];
    virtualisation =
      valid combined
      && combined.virtualisation.libvirtd.enable
      && combined.virtualisation.podman.enable
      && combined.virtualisation.podman.defaultNetwork.settings.dns_enabled
      && combined.services.caddy.enable;
  };
in
{
  modules =
    assert lib.assertMsg (lib.all (x: x) (lib.attrValues checks))
      "cirius-networking checks failed: ${
        lib.concatStringsSep ", " (lib.attrNames (lib.filterAttrs (_: passed: !passed) checks))
      }";
    pkgs.runCommand "cirius-networking-modules" { }
      ''echo '${builtins.toJSON (lib.attrNames checks)}' > "$out"'';
  integration = import ./integration.nix { inherit net pkgs; };
}
