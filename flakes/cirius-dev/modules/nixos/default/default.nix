{
  inputs,
  ...
}:
{
  imports = with builtins; attrValues (removeAttrs inputs.self.nixosModules [ "default" ]);
}
