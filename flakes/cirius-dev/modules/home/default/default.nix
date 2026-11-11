{ inputs, ... }:
{
  imports =
    (with inputs; [
      nixvim.homeModules.default
      nix-index-database.homeModules.default
      codex-desktop-linux.homeManagerModules.default
      deepseek-harness.homeModules.default
    ])
    ++ builtins.attrValues (
      removeAttrs inputs.self.homeModules [
        "default"
        "darwin"
        "ai-common"
        "ai-linux"
      ]
    );
}
