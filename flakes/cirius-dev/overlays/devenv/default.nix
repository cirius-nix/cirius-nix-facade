{ inputs, lib, ... }:
_: prev:
lib.optionalAttrs ((prev.isFakePkgs or false) || prev.stdenv.hostPlatform.isLinux) {
  devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.default;
}
