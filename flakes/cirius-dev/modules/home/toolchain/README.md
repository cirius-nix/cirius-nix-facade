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

Neovim tool commands use executable names from the editor's `PATH`. Start Neovim
inside the project's `devenv shell` to use project tools. Neovim appends its
packaged language servers and helper tools to `PATH` as fallbacks.

VS Code tool settings use absolute paths to the configured Nix packages. Java
settings use the configured JDK directory. To use a different tool from devenv,
override the corresponding setting with its absolute path in workspace settings.

An editor that is already running can retain its previous environment. Restart
the editor from the development shell, or use an editor integration that loads
the project's direnv environment. Changes to a terminal's environment do not
change an existing language server's environment.

| Toolchain | Neovim | VS Code |
| --- | --- | --- |
| Android | Java and Kotlin language servers; google-java-format and ktlint | Java language support, debugging and tests; Gradle tools; Kotlin syntax |
| AWS | Terraform language server; Terraform and HCL formatting | HashiCorp Terraform language support and formatting; HCL syntax |
| C/C++ | clangd; clang-format; CTest adapter | clangd and formatting; CMake tools; LLDB debug adapter |
| Go | gopls; goimports; Go test adapter | Go extension; gopls, goimports and Delve from Nix |
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

## Platform and Framework tools

For [Cirius Go Platform](https://github.com/hieutran21198/cirius-go-platform)
and [Artifact Driven](https://github.com/hieutran21198/Artifact-Driven-Framework),
enable `cnix-dev.useRecommendedPackages`, `cnix-dev.git.enable` and
`cnix-dev.toolchain.{go,nodejs,aws}.enable` in the existing Home Manager config.
Editors are optional.

The Go module selects `go_1_27`, builds `go-tools` with `buildGo127Module`
for Staticcheck compatibility, and provides `gofumpt` and `govulncheck`. Race
tests also need a C compiler: the C++ toolchain supplies Clang and its `cc`
command when enabled. AWS includes Atmos and jq without relying on host system
packages. Recommended packages include Python,
prek, Task, curl, tar and PostgreSQL binaries for Tenant CRM's disposable
integration tests. Git and gh come from the Git module; Node.js includes npm.

Versions follow the consumer's `nixpkgs`. Compare installed versions with
Platform's `go.work`, `package.json` and `infra/terraform/versions.env`.
Use `npm ci` for its locked web tools. Browser tests use each repository's
pinned `requirements-browser.txt` and Playwright's matching Chromium in a
project virtual environment; they also need local sockets and browser launch
permission.

Optional local service tasks still need working `docker compose`, a container
runtime, PostgreSQL containers and the Identity Cognito emulator. Installing
PostgreSQL binaries does not start or configure these services. Follow project
instructions for environment variables, runtime secret loading, `.env`
precedence and hook installation; these packages do not replace that setup.

The existing recommended bundle still enables `programs.devenv`. To omit it
from the local profile, override `programs.devenv.enable = lib.mkForce false;`
in the consuming Home Manager module. Removing project shell instructions and
validating their environment behavior remain separate work.
