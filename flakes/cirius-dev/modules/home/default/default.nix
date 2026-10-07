{
  inputs,
  ...
}:
{
  imports = with inputs; [
    self.homeModules."editor/default"
    self.homeModules."ai/default"
    self.homeModules.git
  ];
}
