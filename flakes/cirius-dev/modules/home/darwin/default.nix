{ inputs, ... }:
{
  # Import this instead of default on macOS. Linux desktop wrappers stay out
  # of the module graph; the remaining modules share their platform guards.
  imports = [
    inputs.nixvim.homeModules.default
    inputs.nix-index-database.homeModules.default
  ]
  ++ builtins.attrValues (
    builtins.removeAttrs inputs.self.homeModules [
      "default"
      "darwin"
      "ai"
      "ai-linux"
    ]
  );
}
