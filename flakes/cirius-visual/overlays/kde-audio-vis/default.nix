{
  inputs,
  lib,
  ...
}:
_: prev:
lib.optionalAttrs ((prev.isFakePkgs or false) || prev.stdenv.hostPlatform.isLinux) {
  plasma-audio-visualizer = inputs.kde-audio-vis.packages.${prev.stdenv.hostPlatform.system}.default;
}
