{ inputs, ... }: _: prev: {
  devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.default;
}
