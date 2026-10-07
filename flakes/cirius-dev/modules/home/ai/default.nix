{
  config,
  pkgs,
  namespace,
  lib,
  ...
}:
{

  options.${namespace}.ai = {
    useRecommendedPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use recommended packages for AI.";
    };
    useClients = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "List of AI clients to use. Options: claude, codex";
    };
  };

  config =
    let
      inherit (config.${namespace}.ai) useClients useRecommendedPackages;

      # util to check if x is in useClients
      ifClient = client: lib.elem client useClients;
    in
    lib.mkMerge [
      (lib.mkIf useRecommendedPackages {
        home.packages = with pkgs; [
          llm-agents.skills-installer
        ];
      })

      (lib.mkIf (ifClient "claude") {
        home.packages = with pkgs; [
          llm-agents.claude
          llm-agents.claude-desktop
        ];
      })

      (lib.mkIf (ifClient "codex") {
        home.packages = with pkgs; [
          llm-agents.codex
        ];
      })

      (lib.mkIf (ifClient "opencode") {
        home.packages = with pkgs; [
          llm-agents.opencode2
          llm-agents.opencode2-desktop
        ];
      })

      (lib.mkIf (ifClient "multica") {
        home.packages = with pkgs; [
          llm-agents.multica
          llm-agents.multica-desktop
        ];
      })

      (lib.mkIf (ifClient "multica") {
        home.packages = with pkgs; [
          llm-agents.command-code
        ];
      })
    ];
}
