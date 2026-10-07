{
  namespace,
  lib,
  config,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.cpp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable C++ toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.cpp) enable;
      inherit (config.${namespace}.editor) nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          clang
          clang-tools
          cmake
          ninja
          gnumake
          pkg-config
          gdb
          lldb
          ccache
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          formatter = {
            fileTypes = {
              c = [ "clang_format" ];
              cpp = [ "clang_format" ];
              objc = [ "clang_format" ];
              objcpp = [ "clang_format" ];
              cuda = [ "clang_format" ];
            };
            tools.clang_format.command = "clang-format";
          };
          tests.adapters.ctest.enable = true;
          lsp = {
            servers.clangd = {
              enable = true;
              packageFallback = true;
              config = {
                cmd = [
                  (lib.getExe' pkgs.clang-tools "clangd")
                  "--background-index"
                  "--clang-tidy"
                  "--completion-style=detailed"
                  "--header-insertion=iwyu"
                ];

                filetypes = [
                  "c"
                  "cpp"
                  "objc"
                  "objcpp"
                  "cuda"
                ];

                root_markers = [
                  "compile_commands.json"
                  "compile_flags.txt"
                  "CMakeLists.txt"
                  "Makefile"
                  ".git"
                ];
              };
            };
          };
        };
      })
    ];

}
