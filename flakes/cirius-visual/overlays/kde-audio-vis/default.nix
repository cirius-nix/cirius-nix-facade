{
  inputs,
  ...
}:
_: prev: {
  plasma-audio-visualizer = inputs.kde-audio-vis.packages.${prev.stdenv.hostPlatform.system}.default;
}
