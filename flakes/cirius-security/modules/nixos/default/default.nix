{
  inputs,
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
    ++ attrValues (removeAttrs inputs.self.nixosModules [ "default" ]);
}
