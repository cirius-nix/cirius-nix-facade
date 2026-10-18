# Toolchain editor support

Enable a toolchain and an editor to load that toolchain's editor configuration.
Each editor can be enabled separately. For example:

```nix
{
  cnix-dev = {
    editor.nvim.enable = true;
    editor.code.enable = true;
    toolchain = {
      nix.enable = true;
      nodejs.enable = true;
      go.enable = true;
    };
  };
}
```

The modules install VS Code extensions in the default profile. Formatting on
save applies to the configured languages. Workspace settings can override these
user settings. Neovim uses Conform for formatting and Nixvim for language servers.

Tool commands use executable names from the editor's `PATH`. Start the editor
inside the project's `devenv shell` to use project tools. Neovim appends its
packaged language servers to `PATH` as fallbacks. Oxc uses its extension's project
and tool discovery; the configuration clears the absolute paths supplied by
Nixpkgs. Java uses the extension's JDK discovery instead of a fixed Nix store path.

An editor that is already running can retain its previous environment. Restart
the editor from the development shell, or use an editor integration that loads
the project's direnv environment. Changes to a terminal's environment do not
change an existing language server's environment.

| Toolchain | Neovim | VS Code |
| --- | --- | --- |
| Android | Java and Kotlin language servers; google-java-format and ktlint | Java language support, debugging and tests; Gradle tools; Kotlin syntax |
| AWS | Terraform language server; Terraform and HCL formatting | HashiCorp Terraform language support and formatting; HCL syntax |
| C/C++ | clangd; clang-format; CTest adapter | clangd and formatting; CMake tools; LLDB debug adapter |
| Go | gopls; goimports; Go test adapter | Go extension; gopls, goimports and Delve from the development environment |
| LaTeX | texlab; latexindent; VimTeX with Zathura | LaTeX Workshop; latexindent; build on save and PDF preview |
| Markdown | Marksman; markdownlint | Built-in Markdown support; markdownlint and formatting |
| Nix | nixd; Statix; nixfmt | Nix IDE with nixd and nixfmt |
| Node.js | TypeScript language server; Oxlint; Oxfmt; Jest and Vitest adapters | Built-in TypeScript support; Oxc linting, formatting and lint fixes on explicit saves |
| Unity | OmniSharp; CSharpier | C#, C# Dev Kit and Unity extensions; C# formatting |

Use Android Studio for Android SDK, emulator and device workflows. The packaged
VS Code Kotlin extension supplies syntax support; it does not supply Kotlin
completion or diagnostics. Neovim uses the packaged Kotlin language server.

In Unity, generate the project's solution and project files before you open C#
files in either editor. Select the external editor in Unity's preferences.
Android and Unity project SDK versions still come from the project.

AWS editor support covers the Terraform and HCL tools in the AWS toolchain.
Use the installed AWS CLI for account and resource operations.

Nix language support now follows `cnix-dev.toolchain.nix.enable`. Enable that
option to retain Nix language support when you enable Neovim.
