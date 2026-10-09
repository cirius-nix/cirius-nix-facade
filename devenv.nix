{
  pkgs,
  ...
}:
{
  packages = with pkgs; [ go-task ];
  languages.nix = {
    enable = true;
  };
}
