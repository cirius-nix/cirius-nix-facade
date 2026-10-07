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
      sops-nix.homeManagerModules.sops
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);
}
