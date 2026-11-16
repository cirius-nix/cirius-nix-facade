# nix eval --impure --json --file flakes/cirius-visual/tests/desktop-selection.nix --apply 'test: test {}'
{
  system ? builtins.currentSystem,
  visual ? builtins.getFlake ("path:" + toString ./..),
}:
let
  inherit (visual.inputs) nixpkgs;
  inherit (nixpkgs) lib;
  desktops = [
    "unset"
    "kde"
    "gnome"
    "cosmic"
  ];
  systemFor =
    desktop:
    (lib.nixosSystem {
      inherit system;
      modules = [
        visual.nixosModules.default
        {
          cnix-visual.desktop-environment.use = desktop;
          system.stateVersion = "25.11";
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          boot.loader.grub.enable = false;
        }
      ];
    }).config;
  valid = c: lib.all (a: a.assertion) c.assertions;
  checks = lib.genAttrs desktops (
    desktop:
    let
      os = systemFor desktop;
    in
    assert valid os;
    assert os.services.desktopManager.plasma6.enable == (desktop == "kde");
    assert os.services.desktopManager.gnome.enable == (desktop == "gnome");
    assert os.services.desktopManager.cosmic.enable == (desktop == "cosmic");
    assert os.services.displayManager.plasma-login-manager.enable == (desktop == "kde");
    assert os.services.displayManager.gdm.enable == (desktop == "gnome");
    assert os.services.displayManager.cosmic-greeter.enable == (desktop == "cosmic");
    assert
      desktop != "cosmic"
      || (
        os.hardware.graphics.enable
        && os.services.pipewire.enable
        && os.services.pipewire.pulse.enable
        && os.xdg.portal.enable
      );
    true
  );
in
checks
