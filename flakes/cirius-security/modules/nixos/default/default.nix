{
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  imports =
    (with inputs; [
      sops-nix.nixosModules.sops
    ])
    ++ (attrValues (removeAttrs inputs.self.nixosModules [ "default" ]))
    ++ ([
      (lib.mkAliasOptionModule [ namespace "pki" ] [ "security" "pki" ])
      (lib.mkAliasOptionModule
        [
          namespace
          "secret-mgt"
          "placeholder"
        ]
        [ "sops" "placeholder" ]
      )
    ]);

  config = {
    environment.systemPackages = with pkgs; [
      sops
      age
    ];
  };
}
