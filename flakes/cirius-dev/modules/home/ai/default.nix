{ inputs, ... }:
{
  # Preserve the Linux entry point for consumers importing homeModules.ai.
  imports = [
    inputs.self.homeModules.ai-common
    inputs.self.homeModules.ai-linux
  ];
}
