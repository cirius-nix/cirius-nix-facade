{
  inputs,
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
          llm-agents.claude-code
          llm-agents.claude-desktop
        ];
      })

      (lib.mkIf (ifClient "codex") {
        home.packages = with pkgs; [
          llm-agents.codex
        ];

        programs.codexDesktopLinux = {
          enable = true;
          linuxFeatures = [
            # "shallow-repository-watches"
          ];
        };
      })

      (lib.mkIf (ifClient "opencode") {
        home.packages = with pkgs; [
          llm-agents.opencode2
          llm-agents.opencode2-desktop
        ];
      })

      # https://moraxyc.github.io/deepseek-harness.nix
      (lib.mkIf (ifClient "deepseek") {
        programs.dsh = {
          enable = true;
          profiles = {
            tui.bundles = [ pkgs.dsh.bundles.tui ];
            desktop.bundles = [ pkgs.dsh.bundles.notification ];
          };
          desktop = {
            enable = true;
            profile = config.programs.dsh.profiles.desktop.materializedName;
          };
          defaultProfile = config.programs.dsh.profiles.tui.materializedName;
        };
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

      (lib.mkIf (ifClient "copilot") {
        programs.nixvim.plugins = {
          copilot-lua = {
            enable = true;
            settings = {
              suggestion.enabled = false;
              panel.enabled = false;
            };
          };
          blink-cmp-copilot = {
            enable = true;
          };
        };
        ${namespace}.editor.nvim.settings.completion = {
          sources = [ "copilot" ];
          providers = {
            copilot = {
              async = true;
              module = "blink-cmp-copilot";
              name = "copilot";
              score_offset = 95;
            };
          };
        };
      })
    ];
}
