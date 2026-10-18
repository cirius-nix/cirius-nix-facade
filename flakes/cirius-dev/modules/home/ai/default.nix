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

        programs.claude-code = {
          enable = true;
          package = pkgs.llm-agents.claude-code;
          mutableSettings = true;
          settings = {
            attribution = {
              commit = "";
              pr = "";
              sessionUrl = false;
            };
          };
        };
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

      (lib.mkIf (ifClient "gemini") {
        programs.antigravity = {
          enable = true;
          package = pkgs.antigravity-fhs;
        };
        programs.antigravity-cli = {
          enable = true;
          package = pkgs.llm-agents.antigravity-cli;
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
        programs.dsh =
          let
            pkg = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
          in
          {
            enable = true;
            package = pkg;
            profiles = {
              tui.bundles = [ pkg.bundles.tui ];
              desktop.bundles = [ pkg.bundles.notification ];
            };
            desktop = {
              enable = true;
              package = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh-desktop;
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
