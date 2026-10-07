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
      nixvim.homeModules.default
    ])
    ++ attrValues (removeAttrs inputs.self.homeModules [ "default" ]);
}
