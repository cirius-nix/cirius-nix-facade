{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.latex = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable latex toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.latex) enable;
      inherit (config.${namespace}.editor) nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          zathura
          texliveMedium
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        programs.nixvim.plugins.vimtex = {
          enable = true;
          settings = {
            view_method = "zathura";
            compiler_method = "latexmk";
            compiler_latexmk = {
              continuous = 1;
              options = [
                "-pdf"
                "-interaction=nonstopmode"
                "-synctex=1"
              ];
            };
          };
        };

        ${namespace}.editor.nvim.settings = {
          formatter = {
            fileTypes.tex = [ "latexindent" ];
            tools.latexindent.command = "latexindent";
          };

          lsp.servers.texlab = {
            enable = true;
            packageFallback = true;

            config = {
              cmd = [ "texlab" ];

              settings.texlab = {
                build.onSave = false;

                forwardSearch = {
                  executable = "zathura";
                  args = [
                    "--synctex-forward"
                    "%l:1:%f"
                    "%p"
                  ];
                };
              };
            };
          };

        };
      })
    ];
}
