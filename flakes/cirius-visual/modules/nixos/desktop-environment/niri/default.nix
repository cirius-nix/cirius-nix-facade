{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.${namespace}.desktop-environment) use niri;
in
{
  options.${namespace}.desktop-environment.niri.enable =
    lib.mkEnableOption "Niri as an additional login session";

  config = lib.mkIf niri.enable {
    programs.niri = {
      enable = true;
      useNautilus = false;
    };

    # The upstream Niri module assumes Niri is the primary session.
    services.displayManager.defaultSession = lib.mkIf (use != "unset") (
      lib.mkOverride 999 (
        {
          kde = "plasma";
          pantheon = "pantheon-wayland";
        }
        .${use} or null
      )
    );

    environment.systemPackages = [ pkgs.xwayland-satellite ];
  };
}
