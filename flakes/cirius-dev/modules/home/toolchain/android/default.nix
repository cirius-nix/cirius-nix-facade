{
  config,
  namespace,
  lib,
  pkgs,
  ...
}:
{
  options.${namespace}.toolchain.android = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Android toolchain.";
    };
  };

  config =
    let
      inherit (config.${namespace}.toolchain.android) enable;
      inherit (config.${namespace}.editor) code nvim;
    in
    lib.mkMerge [
      (lib.mkIf enable {
        home.packages = with pkgs; [
          android-studio
          jdk21
          gradle
          jdt-language-server
          kotlin-language-server
          ktlint
          google-java-format
        ];
      })

      (lib.mkIf (enable && nvim.enable) {
        ${namespace}.editor.nvim.settings = {
          lsp.servers = {
            jdtls = {
              enable = true;
              package = pkgs.jdt-language-server;
              packageFallback = true;
            };
            kotlin_language_server = {
              enable = true;
              package = pkgs.kotlin-language-server;
              packageFallback = true;
            };
          };
          formatter = {
            fileTypes = {
              java = [ "google-java-format" ];
              kotlin = [ "ktlint" ];
            };
            tools = {
              "google-java-format".command = "google-java-format";
              ktlint.command = "ktlint";
            };
          };
        };
      })

      (lib.mkIf (enable && code.enable) {
        programs.vscode.profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-gradle
            mathiasfrohlich.kotlin
          ];
          userSettings = {
            "java.jdt.ls.java.home" = "${pkgs.jdk21}";
            "java.import.gradle.java.home" = "${pkgs.jdk21}";
            "[java]" = {
              "editor.defaultFormatter" = "redhat.java";
              "editor.formatOnSave" = true;
            };
          };
        };
      })
    ];
}
