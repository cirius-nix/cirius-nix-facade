{
  inputs,
  namespace,
  ...
}:
{
  imports =
    (with inputs; [
      stylix.nixosModules.stylix
    ])
    ++ (builtins.attrValues (removeAttrs inputs.self.nixosModules [ "default" ]));
}
