{
  config,
  namespace,
  lib,
  pkgs,
  inputs,
  ...
}:
{
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

    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          onlyoffice-desktopeditors
          pdfarranger
          poppler-utils
          calibre-no-speech
          teams-for-linux
          thunderbird
        ];
        programs.obsidian = {
          enable = true;
          cli.enable = true;
        };
      })

      (lib.mkIf (enable && (hasLevel "technical")) {
        home.packages = with pkgs; [
          pandoc
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
