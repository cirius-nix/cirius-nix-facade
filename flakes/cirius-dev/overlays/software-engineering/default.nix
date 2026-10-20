{ inputs, ... }: _: prev: {
  inherit (inputs.software-engineering.packages.${prev.hostPlatform.system}) se-adopt artifact-plane;
}
