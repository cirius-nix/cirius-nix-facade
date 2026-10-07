{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.homeModules.sprite
  ];

  config = {
    home.packages = with pkgs; [
      inkscape
      blender
      imagemagick
      krita
    ];
  };
}
