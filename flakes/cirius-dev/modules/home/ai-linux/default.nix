{
  inputs,
  config,
  pkgs,
  namespace,
  lib,
  ...
}:
let
  ifClient = client: lib.elem client config.${namespace}.ai.useClients;
in
{
  config = lib.mkMerge [
    (lib.mkIf (ifClient "codex") {
      programs.codexDesktopLinux = {
        enable = true;
        linuxFeatures = [
          "computer-use-linux"
          "remote-mobile-control"
          "remote-control-ui"
        ];
      };
    })

    (lib.mkIf (ifClient "gemini") {
      programs.antigravity = {
        enable = true;
        package =
          inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-no-fhs;
      };
    })
    # https://moraxyc.github.io/deepseek-harness.nix
    (lib.mkIf (ifClient "deepseek") {
      programs.dsh =
        let
          pkg = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
        in
        {
          enable = true;
          package = pkg;
          profiles = {
            tui.bundles = [ pkg.bundles.tui ];
            desktop.bundles = [ pkg.bundles.notification ];
          };
          desktop = {
            enable = true;
            package = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh-desktop;
            profile = config.programs.dsh.profiles.desktop.materializedName;
          };
          defaultProfile = config.programs.dsh.profiles.tui.materializedName;
        };
    })

  ];
}
