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
      inherit (config.${namespace}.editor) code;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          (unityhub.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              wrapProgram $out/opt/unityhub/unityhub \
                --prefix LD_LIBRARY_PATH : "${pkgs.ncurses}/lib"
            '';
          }))
          git-lfs
          vulkan-tools
        ];
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
          ms-dotnettools.csharp
          ms-dotnettools.csdevkit
          visualstudiotoolsforunity.vstuc
        ];
      })
    ];
}
