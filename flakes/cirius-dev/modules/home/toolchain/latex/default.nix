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
      inherit (config.${namespace}.editor) code nvim;
      tex = pkgs.texliveMedium.withPackages (ps: [ ps.latexindent ]);
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          zathura
          tex
          texlab
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        programs.nixvim.plugins.vimtex = {
          enable = true;
          # Use the development environment before the packaged fallback tools.
          texlivePackage = null;
          zathuraPackage = null;
          xdotoolPackage = null;
          pstreePackage = null;
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
        programs.nixvim.extraPackagesAfter = [
          tex
          pkgs.zathura
          pkgs.pstree
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.xdotool ];

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

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = [ pkgs.vscode-extensions.james-yu.latex-workshop ];
          userSettings = {
            "latex-workshop.latex.autoBuild.run" = "onSave";
            "latex-workshop.latex.outDir" = "%DIR%";
            "latex-workshop.formatting.latex" = "latexindent";
            "latex-workshop.formatting.latexindent.path" = lib.getExe' tex "latexindent";
            "latex-workshop.view.pdf.viewer" = "tab";
          }
          // lib.genAttrs [ "[latex]" "[tex]" "[bibtex]" ] (_: {
            "editor.defaultFormatter" = "James-Yu.latex-workshop";
            "editor.formatOnSave" = true;
          });
        };
      })
    ];
}
