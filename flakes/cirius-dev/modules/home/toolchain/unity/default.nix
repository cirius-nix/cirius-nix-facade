{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.unity = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Unity toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.unity) enable;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages =
          (with pkgs; [
            git-lfs
            dotnet-sdk
            omnisharp-roslyn
            csharpier
          ])
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
            with pkgs;
            [
              (unityhub.overrideAttrs (old: {
                postInstall = (old.postInstall or "") + ''
                  wrapProgram $out/opt/unityhub/unityhub \
                    --prefix LD_LIBRARY_PATH : "${pkgs.ncurses}/lib"
                '';
              }))
              vulkan-tools
            ]
          );
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          lsp.servers.omnisharp = {
            enable = true;
            package = pkgs.omnisharp-roslyn;
            packageFallback = true;
          };
          formatter.fileTypes.cs = [ "csharpier" ];
        };
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
          ms-dotnettools.csharp
          ms-dotnettools.csdevkit
          visualstudiotoolsforunity.vstuc
        ];
        programs.vscode.profiles.default.userSettings."[csharp]" = {
          "editor.defaultFormatter" = "ms-dotnettools.csharp";
          "editor.formatOnSave" = true;
        };
      })
    ];
}
