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
      inherit (config.${namespace}.editor) code;

      # util to check if x is in useClients
      ifClient = client: lib.elem client useClients;
    in
    lib.mkMerge [
      (lib.mkIf useRecommendedPackages {
        home.packages = with pkgs; [
          # TODO: add more recommended packages here
        ];
      })

      (lib.mkIf (ifClient "orca") {
        home.packages = with pkgs.llm-agents; [
          orca
        ];
      })

      (lib.mkIf (ifClient "t3code") {
        home.packages = with pkgs.llm-agents; [
          t3code
          t3code-desktop
        ];
      })

      (lib.mkIf (ifClient "claude") {
        home.packages =
          with pkgs;
          [
            llm-agents.claude-code
            llm-agents.claude-agent-acp
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.llm-agents.claude-desktop ];

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
        home.packages =
          with pkgs;
          [
            llm-agents.codex
            llm-agents.codex-acp
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.bubblewrap ];

      })

      (lib.mkIf (ifClient "gemini") {
        programs.antigravity-cli = {
          enable = true;
          package = pkgs.llm-agents.antigravity-cli;
        };
      })

      (lib.mkIf ((ifClient "gemini") && code.enable) {
        programs.vscode.profiles.default.extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "google-antigravity";
            publisher = "Google";
            version = "1.8.0";
            hash = "sha256-h2GTvOkESX96Ce/ja3+vbV8qH+WA/4VLhj00JR4EOOY=";
          }
        ];
      })

      (lib.mkIf (ifClient "opencode") {
        home.packages =
          with pkgs;
          [
            llm-agents.opencode2
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.llm-agents.opencode2-desktop ];

        programs.opencode = {
          enable = true;
          package = pkgs.llm-agents.opencode2;
        };
      })

      (lib.mkIf (ifClient "kimi") {
        home.packages = with pkgs.llm-agents; [ kimi-code ];
      })

      (lib.mkIf (ifClient "commandcode") {
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
