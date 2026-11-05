{ inputs, lib, ... }:
_: prev:
lib.optionalAttrs ((prev.isFakePkgs or false) || prev.stdenv.hostPlatform.isLinux) {
  kwin-effects-glass = inputs.kwin-effects-glass.packages.${prev.stdenv.hostPlatform.system}.default;
}
