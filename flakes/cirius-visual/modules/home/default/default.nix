{
  inputs,
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports =
    (
      with inputs;
      with lib;
      [
        stylix.homeModules.stylix
        plasma-manager.homeModules.plasma-manager
        (mkAliasOptionModule [ namespace "infra" "fonts" ] [ "stylix" "fonts" ])
      ]
    )
    ++ (with builtins; attrValues (removeAttrs inputs.self.homeModules [ "default" ]));

  options.${namespace} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the visual module.";
    };
    useRecommendedFonts = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use recommended fonts for stylix.";
    };
  };

  config =
    let
      inherit (config.${namespace}) enable useRecommendedFonts;
      disableAll =
        listNames:
        lib.listToAttrs (
          map (name: {
            name = name;
            value = {
              enable = false;
            };
          }) listNames
        );
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          base16-schemes
          qt6Packages.qtstyleplugin-kvantum
        ];
        stylix.targets = disableAll [ "xresources" ];
        stylix = {
          enable = true;
          autoEnable = false;
          base16Scheme = {
            system = "base16";
            name = "Adwaita Inspired Dark";
            author = "Minh Hieu Tran";
            variant = "dark";
            palette = {
              base00 = "1d1d20";
              base01 = "222226";
              base02 = "2e2e32";
              base03 = "5e5c64";
              base04 = "9a9996";
              base05 = "f6f5f4";
              base06 = "deddda";
              base07 = "ffffff";
              base08 = "ed333b";
              base09 = "ff7800";
              base0A = "f6d32d";
              base0B = "33d17a";
              base0C = "62a0ea";
              base0D = "3584e4";
              base0E = "c061cb";
              base0F = "b5835a";
            };
          };
        };
      })
      # fonts
      (lib.mkIf useRecommendedFonts {
        home.packages =
          with pkgs;
          with pkgs.nerd-fonts;
          [
            monaspace
            noto-fonts-color-emoji
          ];

        fonts.fontconfig = {
          enable = true;
        };

        stylix.fonts = {
          monospace = {
            name = "MonaspiceNe Nerd Font Mono";
            package = pkgs.nerd-fonts.monaspace;
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
          sizes = {
            terminal = 12;
          };
        };
      })
    ];
}
