{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.virt-desktop =
    let
      inherit (lib) cnix-lib;
    in
    {
      enable = cnix-lib.mkBoolOpt {
        default = false;
        description = "Whether to enable virtual desktop support.";
      };
      settings = {
        dir = cnix-lib.mkPathOpt {
          description = "Directory containing custom EDID files.";
        };
        edids = cnix-lib.mkAttrsOpt {
          ofType = lib.types.submodule {
            options = {
              name = cnix-lib.mkStrOpt {
                description = "Name of the EDID file.";
              };
              mode = cnix-lib.mkStrOpt {
                description = "Display mode for the EDID.";
              };
            };
          };
          default = { };
          description = "Attributes of EDID files to be used for virtual displays.";
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

          ${lib.concatMapStrings (name: ''
            cp ${settings.dir + "/${name}"} \
               $out/lib/firmware/edid/${name}
          '') (builtins.attrNames edids)}
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
