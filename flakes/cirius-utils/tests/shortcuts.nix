# nix eval --impure --json --file flakes/cirius-utils/tests/shortcuts.nix --apply 'test: (test {}).evaluation'
# nix build --impure --file flakes/cirius-utils/tests/shortcuts.nix cosmic --no-link
{
  system ? builtins.currentSystem,
  utils ? builtins.getFlake ("path:" + toString ./..),
}:
let
  inherit (utils.inputs) nixpkgs home-manager;
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${system};
  path = "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom";
  homeFor =
    desktop: extra:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs.host = "shortcut-check";
      modules = [
        utils.homeModules.default
        {
          home.username = "tester";
          home.homeDirectory = "/home/tester";
          home.stateVersion = "25.11";
          cnix-utils = {
            settings.managedDesktopEnvironment = desktop;
            desktop-environment.shortcuts = {
              enable = desktop != "unset" && desktop != "pantheon";
              useRecommendedShortcuts = desktop != "pantheon";
            };
          };
        }
        extra
      ];
    }).config;
  homes = lib.genAttrs [
    "unset"
    "kde"
    "gnome"
    "cosmic"
    "pantheon"
  ] (desktop: homeFor desktop { });
  custom = homeFor "cosmic" {
    cnix-utils.desktop-environment.shortcuts = {
      useRecommendedShortcuts = lib.mkForce false;
      settings = {
        extendedActions.cosmic."desktop.toggle-tiling" = "ToggleTiling";
        bindings = {
          "win.close" = [ ];
          "desktop.toggle-tiling" = [
            [
              "Meta"
              "y"
            ]
          ];
          "win.minimize" = [
            [
              "SUPER"
              "m"
            ]
          ];
        };
      };
    };
  };
in
{
  evaluation = lib.mapAttrs (
    desktop: home:
    assert lib.all (a: a.assertion) home.assertions;
    assert builtins.hasAttr path home.xdg.configFile == (desktop == "cosmic");
    assert
      !(lib.elem desktop [
        "cosmic"
        "pantheon"
      ])
      || (home.programs.plasma.shortcuts == { } && home.dconf.settings == { });
    true
  ) homes;
  cosmic = homes.cosmic.xdg.configFile.${path}.source;
  custom = custom.xdg.configFile.${path}.source;
  checks = pkgs.runCommand "cosmic-shortcut-checks" { } ''
    PYTHONDONTWRITEBYTECODE=1 ${pkgs.python3}/bin/python ${./test_cosmic_shortcuts.py} \
      ${../modules/home/desktop-environment/shortcuts/_cosmic.shortcuts.py} \
      ${pkgs.cosmic-comp}/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults \
      ${homes.cosmic.xdg.configFile.${path}.source} \
      ${custom.xdg.configFile.${path}.source} \
      ${lib.getLib pkgs.libxkbcommon}/lib/libxkbcommon.so.0
    touch "$out"
  '';
}
