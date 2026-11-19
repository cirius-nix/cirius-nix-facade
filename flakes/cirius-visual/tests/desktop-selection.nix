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
    desktop: niri:
    (lib.nixosSystem {
      inherit system;
      modules = [
        visual.nixosModules.default
        {
          cnix-visual.desktop-environment.use = desktop;
          cnix-visual.desktop-environment.niri.enable = niri;
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
  check =
    desktop: niri:
    let
      os = systemFor desktop niri;
      baseline = systemFor desktop false;
    in
    assert valid os;
    assert os.services.desktopManager.plasma6.enable == (desktop == "kde");
    assert os.services.desktopManager.gnome.enable == (desktop == "gnome");
    assert os.services.desktopManager.cosmic.enable == (desktop == "cosmic");
    assert os.services.displayManager.plasma-login-manager.enable == (desktop == "kde");
    assert os.services.displayManager.gdm.enable == (desktop == "gnome");
    assert os.services.displayManager.cosmic-greeter.enable == (desktop == "cosmic");
    assert os.programs.niri.enable == niri;
    assert
      lib.elem "niri" (
        lib.concatMap (pkg: pkg.providedSessions) os.services.displayManager.sessionPackages
      ) == niri;
    assert !niri || desktop != "unset" || os.services.displayManager.defaultSession == "niri";
    assert
      !niri
      || desktop == "unset"
      || (
        os.services.displayManager.defaultSession == baseline.services.displayManager.defaultSession
        &&
          os.services.displayManager.sessionData.autologinSession
          == baseline.services.displayManager.sessionData.autologinSession
      );
    assert
      desktop != "cosmic"
      || (
        os.hardware.graphics.enable
        && os.services.pipewire.enable
        && os.services.pipewire.pulse.enable
        && os.xdg.portal.enable
      );
    true;
in
lib.genAttrs desktops (desktop: check desktop false && check desktop true)
