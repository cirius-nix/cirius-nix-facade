{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable office tools.";
    };
  };

  config =
    let
      inherit (config.${namespace}) enable;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          onlyoffice-desktopeditors
          calibre-no-speech
          teams-for-linux
        ];
        programs.thunderbird = {
          enable = true;
        };
        programs.obsidian = {
          enable = true;
          cli.enable = true;
        };
      })
    ];
}
