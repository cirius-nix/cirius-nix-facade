{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.virt-desktop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable virtual desktop configuration.";
    };
    settings = {
      dir = lib.mkOption {
        type = with lib.types; path;
        description = "Directory for virtual desktop configuration files.";
      };
      edids = lib.mkOption {
        type =
          with lib.types;
          attrsOf (submodule {
            options = {
              name = lib.mkOption {
                type = str;
                description = "Name of the display output.";
              };
              mode = lib.mkOption {
                type = str;
                description = "Display mode for the output.";
              };
            };
          });
      };
    };
  };
  config =
    let
      inherit (config.${namespace}.virt-desktop) enable settings;
      mkEdidPackage =
        edids:
        pkgs.runCommand "custom-display-edids" { } ''
          mkdir -p $out/lib/firmware/edid

          ${lib.concatMapStrings (
            name:
            let
              settings = builtins.getAttr name edids;
            in
            ''
              cp ${settings.dir + "/${name}"} \
                 $out/lib/firmware/edid/${name}
            ''
          ) (builtins.attrNames edids)}
        '';
    in
    lib.mkMerge [
      (lib.mkIf enable {
        hardware.display = {
          edid = {
            enable = true;
            packages = [ (mkEdidPackage settings.edids) ];
          };
          outputs = lib.mapAttrs' (name: value: {
            name = value.name;
            value = {
              edid = name;
              mode = value.mode;
            };
          }) settings.edids;
        };
      })
    ];
}
