{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (lib.mkAliasOptionModule [ namespace "git" "settings" "includes" ] [ "programs" "git" "includes" ])
  ];
  options.${namespace}.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable git tools.";
    };
  };

  config =
    let
      inherit (lib.${namespace}.nvim) mkKeymap;
      inherit (config.${namespace}.git) enable;
      inherit (config.${namespace}.editor) nvim;
      inherit (config.${namespace}) shell;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        programs = {
          git = {
            enable = true;
            settings = {
              core.whitespace = "trailing-space,space-before-tab";
              init.defaultBranch = "main";
              push.autoSetupRemote = true;
              color.ui = "auto";
              diff = {
                tool = "vimdiff";
                mnemonicprefix = true;
              };
              merge.tool = "splice";
              push.default = "simple";
              pull.rebase = true;
              branch.autosetupmerge = true;
              rerere.enabled = true;
              extraConfig = { };
            };

          };
          gh = {
            enable = true;
            extensions = with pkgs; [
              gh-eco
              gh-dash
            ];
            gitCredentialHelper = {
              enable = true;
              hosts = [ "https://github.com" ];
            };
            settings = {
              prompt = "enabled";
              git_protocol = "ssh";
            };
          };
          lazygit = {
            enable = true;
            enableFishIntegration = shell == "fish";
          };
        };
      })

      (lib.mkIf (enable && nvim.enable) {
        programs.nixvim.keymaps = [
          (mkKeymap "<leader>gb" "<cmd>lua Snacks.git.blame_line()<cr>" "󰙨 Find Bug Creator")
        ];
        programs.nixvim.plugins.snacks = {
          settings = {
            styles = {
              blame_line = {
                enabled = true;
                width = 0.6;
                height = 0.6;
                border = true;
                title = " Inspect Crime Scene 󰌵 ";
                title_pos = "center";
                ft = "git";
              };
            };
          };
        };
      })
      (lib.mkIf (enable && shell == "fish") {
        programs.fish.shellAliases = {
          gblame = "git blame -w -M -C --line-porcelain | grep -e '^author ' | cut -d' ' -f2-";
          gco = "git checkout";
          gpl = "git pull origin";
          gps = "git push origin";
          gaa = "git add .";
          gcm = "git commit -m";
        };
      })
    ];
}
