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
      inherit (config.${namespace}.editor) code nvim;
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
                  "clangd"
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

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            llvm-vs-code-extensions.vscode-clangd
            ms-vscode.cmake-tools
            llvm-vs-code-extensions.lldb-dap
          ];
          userSettings = {
            "clangd.path" = lib.getExe' pkgs.clang-tools "clangd";
            "clangd.arguments" = [
              "--background-index"
              "--clang-tidy"
              "--completion-style=detailed"
              "--header-insertion=iwyu"
            ];
            "cmake.cmakePath" = lib.getExe pkgs.cmake;
            "lldb-dap.executable-path" = lib.getExe' pkgs.lldb "lldb-dap";
          }
          // lib.genAttrs [ "[c]" "[cpp]" "[objective-c]" "[objective-cpp]" "[cuda-cpp]" ] (_: {
            "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
            "editor.formatOnSave" = true;
          });
        };
      })
    ];

}
