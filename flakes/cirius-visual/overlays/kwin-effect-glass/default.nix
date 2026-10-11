{ inputs, ... }: _: prev: {
  kwin-effects-glass = inputs.kwin-effects-glass.packages.${prev.stdenv.hostPlatform.system}.default;
}
