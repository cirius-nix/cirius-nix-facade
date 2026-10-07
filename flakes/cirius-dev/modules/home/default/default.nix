{
  inputs,
  ...
}:
{
  imports = with inputs; [
    self.homeModules.editor
    self.homeModules.git
  ];
}
