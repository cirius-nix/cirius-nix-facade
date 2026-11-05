{
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  host ? "mac",
  ...
}:
let
  cfg = config.${namespace};
in
{
  imports = [ inputs.self.homeModules.connectivity ];
  options.${namespace} = {
    enable = lib.mkEnableOption "Cirius utilities";
    settings.dotFileDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the consuming nix-darwin configuration.";
    };
  };
  config = lib.mkIf cfg.enable {
    programs.fish.shellAbbrs = lib.mkIf (cfg.settings.dotFileDir != null) {
      nix-sw = "sudo darwin-rebuild switch --flake ${lib.escapeShellArg cfg.settings.dotFileDir}#${lib.escapeShellArg host}";
      nix-rb = "darwin-rebuild build --flake ${lib.escapeShellArg cfg.settings.dotFileDir}#${lib.escapeShellArg host}";
    };
  };
}
