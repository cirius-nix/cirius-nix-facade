{
  inputs,
  ...
}:
{
  imports = with inputs; [
    nixvim.homeModules.nixvim
    self.homeModules.editor.nvim
  ];
}
