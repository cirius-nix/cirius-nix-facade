{
  config,
  namespace,
  lib,
  ...
}:
{
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
    in
    lib.mkMerge [
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
    ];
}
