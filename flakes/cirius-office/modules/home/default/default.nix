{
  config,
  namespace,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = with inputs; [
    nix-flatpak.homeManagerModules.nix-flatpak
  ];

  options.${namespace} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable office tools.";
    };
    variant = lib.mkOption {
      type = lib.types.enum [
        "basic"
        "technical"
        "research"
      ];
      default = "basic";
      description = "Choose the variant of office tools to install.";
    };
  };

  config =
    let
      inherit (config.${namespace}) enable variant;
      levels = {
        basic = 1;
        technical = 2;
        research = 3;
      };
      hasLevel = level: lib.hasAttr level levels && (levels.${level} <= levels.${variant});

      withflatpakOrigin =
        list: origin:
        lib.map (appId: {
          inherit origin appId;
        }) list;

      withflathubOrigin = list: withflatpakOrigin list "flathub";
    in
    lib.mkMerge [
      (lib.mkIf enable {
        services.flatpak = {
          enable = true;
          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };
          overrides.settings = {
            global = {
              Context.sockets = [
                "wayland"
                "!x11"
                "!fallback-x11"
              ];
              Environment = {
                XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
              };
            };
          };
          remotes = [
            {
              name = "flathub-beta";
              location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
            }
          ];
          packages = withflathubOrigin [ "eu.betterbird.Betterbird" ];
        };

        home.packages = with pkgs; [
          onlyoffice-desktopeditors
          pdfarranger
          poppler-utils
          calibre-no-speech
          teams-for-linux
          flatpak
        ];
        programs.obsidian = {
          enable = true;
          cli.enable = true;
        };
      })

      (lib.mkIf (enable && (hasLevel "technical")) {
        home.packages = with pkgs; [
          pandoc
          texliveMedium
          mermaid-cli
          typst
          drawio
          graphviz
        ];
      })

      (lib.mkIf (enable && (hasLevel "research")) {
        home.packages = with pkgs; [
          # build fail
          # zotero
          jabref
          ocrmypdf
          quarto
        ];
      })
    ];
}
