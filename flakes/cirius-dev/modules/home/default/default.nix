{
  inputs,
  ...
}:
{
  imports = with inputs; [
    self.homeModules."editor/default"
    self.homeModules.git
  ];
}
