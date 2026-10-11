{
  namespace,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = with inputs; [
    fcitx5-lotus.nixosModules.fcitx5-lotus
  ];

  options.${namespace} =
    let
      cnix-lib = inputs.cirius-lib.lib;
    in
    {
      enable = cnix-lib.mkBoolOpt {
        default = false;
        description = "Enable Cirius Nix Vietnam supports";
      };
      inputMethod = {
        users = cnix-lib.mkListOpt {
          ofType = lib.types.str;
          default = [ ];
          description = "List of users to enable fcitx5-lotus input method";
        };
      };
    };

  config =
    let
      inherit (config.${namespace}) enable inputMethod;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
        };
        services.fcitx5-lotus = {
          enable = true;
          inherit (inputMethod) users;
        };
        # Set your time zone.
        time.timeZone = "Asia/Ho_Chi_Minh";

        # Select internationalisation properties.
        i18n = {
          defaultLocale = "en_US.UTF-8";
          extraLocaleSettings = {
            LC_ADDRESS = "vi_VN";
            LC_IDENTIFICATION = "vi_VN";
            LC_MEASUREMENT = "vi_VN";
            LC_MONETARY = "vi_VN";
            LC_NAME = "vi_VN";
            LC_NUMERIC = "vi_VN";
            LC_PAPER = "vi_VN";
            LC_TELEPHONE = "vi_VN";
            LC_TIME = "vi_VN";
          };
        };
      })
    ];
}
