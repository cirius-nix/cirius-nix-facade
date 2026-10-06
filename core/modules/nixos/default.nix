{ pkgs, namespace, ... }: {
  nix = {
    package = pkgs.lixPackageSets.stable.lix;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit namespace; };
  };
}
