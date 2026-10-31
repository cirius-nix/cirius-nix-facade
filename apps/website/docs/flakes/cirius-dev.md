---
title: cirius-dev
sidebar_position: 3
description: Editors, shell, terminal, git, AI clients, nine language toolchains, and a self-hosted GitHub Actions runner — the developer surface, wired so each toolchain drives whichever editor you enabled.
---

# cirius-dev

The developer surface, and the flake with the most moving parts. Its organising
idea is that a toolchain is one switch: enable `toolchain.go` and you get the Go
packages, the Go language server, its formatter, and the editor integration for
whichever editor you turned on — but none of it applies unless the editor is
enabled too. Editors and language tooling are kept independent rather than fused.

| | |
| --- | --- |
| Namespace | `cnix-dev` |
| Module classes | `home`, `nixos` |
| External inputs | `nixvim`, `nix-index-database`, `llm-agents`, `codex-desktop-linux`, `deepseek-harness`, `devenv` |
| Options | 40 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-dev.homeModules.default ];

  cnix-dev.shell = "fish";
  cnix-dev.term.useTerms = [ "ghostty" "herdr" ];

  cnix-dev.editor.nvim.enable = true;
  cnix-dev.editor.code.enable = true;

  cnix-dev.git.enable = true;
  cnix-dev.toolchain.nodejs.enable = true;
  cnix-dev.toolchain.go.enable = true;
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | *(always applies)* | Recommended packages, fastfetch/eza/fzf/direnv/starship |
| `shell` | home | `cnix-dev.shell` | Which shell is enabled |
| `term` | home | `cnix-dev.term.useTerms` | Ghostty, herdr |
| `git` | home | `cnix-dev.git.enable` | git, github-desktop, gh, lazygit, fish aliases |
| `ai` | home | `cnix-dev.ai.useClients` | AI client packages and programs |
| `editor/code` | home | `cnix-dev.editor.code.enable` | VS Code |
| `editor/nvim` | home | `cnix-dev.editor.nvim.enable` | nixvim, leader key, options, keymaps |
| `editor/nvim/plugins` | home | *(requires `editor.nvim.enable`)* | Plugin set, formatter/completion/LSP wiring |
| `toolchain/*` | home | `cnix-dev.toolchain.<name>.enable` | Nine language toolchains |
| `default` | nixos | *(always applies)* | Imports every NixOS module |
| `github-runner` | nixos | `cnix-dev.github-runner.enable` | Self-hosted GitHub Actions runner |

### `home/default` — the always-on base

The aggregate module for this flake, and the only one that applies without an
enable flag. It imports the external home modules (`nixvim`,
`nix-index-database`, `codex-desktop-linux`, `deepseek-harness`) and every sibling
module, then enables fastfetch, eza, fzf, direnv, devenv, starship, and zoxide —
with fish integrations switched on only when `cnix-dev.shell = "fish"`.
`useRecommendedPackages` adds `bruno`, `btop`, `comma`, and `python3`.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.useRecommendedPackages` | `bool` | `false` | Whether to use recommended packages for nvim. | Installs the recommended home package set. |

### `home/shell` — shell selection

Not enable-gated; it is a selector. The value picks exactly one shell program,
and other modules read it to decide whether to add fish integrations.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.shell` | `enum [ "bash" "zsh" "fish" ]` | `"fish"` | Whether to use recommended shell packages. | Enables `programs.bash`/`programs.zsh`/`programs.fish`. |

### `home/term` — terminal

Selects terminals by list. `"ghostty"` enables Ghostty with a tuned config:
40% cell height, clipboard-on-select, balanced padding, and two key tables
(`tab_mgt` and `resize`) for tab and pane management. Fish integration follows
`programs.fish.enable`.

`"herdr"` installs the herdr terminal workspace manager and writes its
`~/.config/herdr/config.toml`: the Atom One light/dark theme following the host
appearance (the same palette as Ghostty's theme), a `ctrl+b` prefix (herdr's
default, so it collides with neither Ghostty's `ctrl+a` keybindings nor fcitx's
`ctrl+space` input toggle), Ghostty-style `v`/`s` splits, `h/j/k/l` focus,
`z` zoom, `r` resize mode, `tab`/`shift+tab` tab switching, `c`/`t` new tab,
clipboard-on-select, in-app agent notifications, and no onboarding or tab-name
prompt. New panes use `cnix-dev.shell`.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.term.useTerms` | `listOf str` | `true` | Whether to use recommended terminal packages. | `"ghostty"` enables and configures Ghostty; `"herdr"` installs and configures herdr. |

The default here is a boolean while the declared type is `listOf str` — a
mismatch in the source. Set the option to an explicit list, for example
`cnix-dev.term.useTerms = [ "ghostty" "herdr" ];`.

### `home/git` — git, gh, lazygit

**Enable:** `cnix-dev.git.enable`

Enables git with the habits worth not re-deriving: `push.autoSetupRemote`,
`pull.rebase`, `rerere`, `push.default = "simple"`, whitespace checking, and
`init.defaultBranch = "main"`. gh is enabled with the git credential helper for
GitHub and the `gh-eco` and `gh-dash` extensions; lazygit is enabled with fish
integration when applicable. With fish selected it also adds `gblame`, `gco`,
`gpl`, `gps`, `gaa`, and `gcm` aliases, and with Neovim enabled it adds a
`<leader>gb` blame-line keymap through the nixvim git integration.

`git.settings.includes` is an alias of `programs.git.includes`, so conditional
includes are written under the facade's namespace.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.git.enable` | `bool` | `false` | Enable git tools. | Enables git, gh, lazygit, and the fish/nvim integrations. |
| `cnix-dev.git.settings.includes` | *(alias of `programs.git.includes`)* | — | — | Sets git config includes. |

### `home/ai` — AI clients

Selection by list, with one flag for the shared installer.

Each client entry pulls its own packages and, where one exists, enables its
program module: `claude` (Claude Code with attribution disabled, plus Claude
Desktop), `codex` (Codex and the desktop app), `gemini` (Antigravity, its CLI,
and the `Google.google-antigravity` VS Code extension when `editor.code` is
enabled), `opencode`, `deepseek` (the `dsh` harness with tui and desktop profiles),
`copilot-lua` and `blink-cmp-copilot` into the nixvim completion sources).

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.ai.useRecommendedPackages` | `bool` | `true` | Whether to use recommended packages for AI. | TODO: |
| `cnix-dev.ai.useClients` | `listOf str` | `[ ]` | List of AI clients to use. Options: claude, codex | Each listed client installs its packages and enables its program module. |

### `home/editor/code` — VS Code

**Enable:** `cnix-dev.editor.code.enable`

Enables `programs.vscode` with `pkgs.vscode.fhs`. The module deliberately does not
touch `profiles.default` itself — extensions and settings arrive from the
toolchain modules that are enabled, so VS Code reflects the same set of languages
as Neovim.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.editor.code.enable` | `bool` | `false` | Enable VSCode editor. | Enables VS Code (FHS package) and gates every toolchain's VS Code block. |

### `home/editor/nvim` — nixvim

**Enable:** `cnix-dev.editor.nvim.enable`

Configures nixvim with a curated preference set: `useRecommendation` applies 45
recommended options (clipboard integration, `inccommand`, `termguicolors`,
2-space indentation, `undofile`, `rg` as grepprg, rounded borders, and so on),
merged under your own `settings.options.extends` so overrides win. Nine default
keymaps cover quitting, window movement, search-highlight clearing, and LSP code
actions, rename, and signature help. ripgrep and git are enabled as dependencies,
and an autocmd disables nixd's document-highlight capability to silence noisy
stderr from the server.

`settings.leaderKey` is applied with `mkForce`, so it cannot be overridden by a
stray `mapleader` definition elsewhere. `settings.lsp.servers` is an alias of
`programs.nixvim.lsp.servers` — this is the path the toolchain modules write to.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.editor.nvim.enable` | `bool` | `false` | Enable Neovim editor. | Enables nixvim with the recommended options, keymaps, and dependencies. |
| `cnix-dev.editor.nvim.settings.leaderKey` | `str` | `" "` | Leader key for Neovim. | Force-sets `globals.mapleader`. |
| `cnix-dev.editor.nvim.settings.options.useRecommendation` | `bool` | `true` | Use recommended Neovim settings. | When true, the 45 recommended options are merged with `extends`; when false, only `extends` applies. |
| `cnix-dev.editor.nvim.settings.options.extends` | `attrsOf anything` | `{ }` | Extend Neovim settings with additional options. | Merged into `programs.nixvim.opts`; your keys win over the recommended ones. |
| `cnix-dev.editor.nvim.settings.lsp.servers.<name>` | *(alias of `programs.nixvim.lsp.servers.<name>`)* | — | — | Adds or configures an LSP server in nixvim. |

### `home/editor/nvim/plugins` — plugin set

There is no option of its own: the module applies whenever
`cnix-dev.editor.nvim.enable` is true. It sets `EDITOR = "nvim"`, installs the
extra runtime packages (`fd`, `ripgrep`, `git`, `trash-cli`), and configures the
plugin set — Snacks (picker, explorer instead of netrw, notifier, scroll,
bigfile), mini (comment, pairs), Conform with format-on-save, none-ls, nix-develop
for direnv-style project shells, Trouble, grug-far, auto-session, Neotest with a
quickfix and split summary, treesitter, lualine, luasnip, blink-cmp with
super-tab completion and ghost text, web-devicons, and which-key.

Thirty keymaps are registered through `lib.cnix-dev.nvim.mkKeymap`: the
`<leader>f*` finder group, the `<leader>l*` LSP group, `<leader>t*` test group,
and the `<leader>e` explorer toggle.

The module also owns the option surface the toolchains write into. Six aliases map
the facade's names onto nixvim plugin settings:

| Option | Alias target | Used by toolchains to |
| --- | --- | --- |
| `…settings.formatter.fileTypes` | conform-nvim `formatters_by_ft` | Choose formatters per filetype |
| `…settings.formatter.tools` | conform-nvim `formatters` | Define formatter tool commands |
| `…settings.tests.adapters` | neotest `adapters` | Register test-runner adapters |
| `…settings.completion.sources` | blink-cmp `sources.default` | Change completion source order |
| `…settings.completion.providers.<name>` | blink-cmp `sources.providers` | Tune a provider (e.g. score offset) |
| `…settings.session.excludeFileTypes` | auto-session `bypass_save_filetypes` | Exclude filetypes from saved sessions |

Because they are aliases, the upstream nixvim documentation applies directly —
there is no facade-specific layer to learn.

### `nixos/github-runner` — self-hosted CI runner

**Enable:** `cnix-dev.github-runner.enable`

Registers one runner per entry in `runners`, keyed by registration name. Each
entry becomes its own systemd service `github-runner-<name>`, with its own
state, logs, and work directories, and can use a different URL, credential,
labels, and package set. Runners execute as dynamic users and have Nix on their
PATH; they do not inherit the host user's packages, so add whatever workflows
need (Node, pnpm, language toolchains) through `extraPackages`.

Authenticate each runner with a token file or a GitHub App, not both.
`tokenFile` should hold a fine-grained PAT with read-and-write access to
self-hosted runners (or a classic PAT with `repo`/`admin:org`); a runner
registration token works for the first registration but expires after an hour
and breaks later re-registrations. `githubApp` derives short-lived tokens from
an App installation instead, which pairs well with `ephemeral` runners
recreated for every job.

Runner data is split across three systemd directories, all per registration
name. Persistent state (credentials and the `.runner` registration) lives in
`/var/lib/github-runner/<name>` — actually `/var/lib/private/…` while the
dynamic user is in effect. Logs live in `/var/log/github-runner/<name>`. The
checkout directory (`$GITHUB_WORKSPACE`) defaults to
`/run/github-runner/<name>`, which is tmpfs and wiped on boot; set `workDir` to
keep builds on disk. Either way the runner clears that directory on every
service start, so it is scratch space, not a cache, and each runner needs its
own `workDir`.

```nix
{ inputs, pkgs, ... }:
{
  imports = [ inputs.cirius-dev.nixosModules.default ];

  cnix-dev.github-runner = {
    enable = true;
    runners = {
      nixos = {
        url = "https://github.com/cirius-nix/cirius-nix-facade";
        tokenFile = "/run/secrets/github-runner";
        extraLabels = [ "nixos" "x86_64-linux" ];
        extraPackages = with pkgs; [ nodejs_24 pnpm ];
      };
      nixos-arm = {
        url = "https://github.com/cirius-nix";
        githubApp = {
          id = 123456;
          login = "cirius-nix";
          privateKeyFile = "/run/secrets/github-app.pem";
        };
        ephemeral = true;
      };
    };
  };
}
```

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.github-runner.enable` | `bool` | `false` | Enable self-hosted GitHub Actions runners. | Registers and starts one `github-runner-<name>` per entry. |
| `cnix-dev.github-runner.runners` | `attrsOf submodule` | `{ }` | Runners keyed by registration name. | Each entry is registered and started as `github-runner-<name>`. |
| `…runners.<name>.url` | `nullOr str` | `null` | Repository or organisation URL the runner registers with. | A repo URL scopes it to one repository; an org URL shares it across the org. |
| `…runners.<name>.tokenFile` | `nullOr path` | `null` | File containing a PAT or registration token. | Authenticates registration; must be set unless `githubApp` is. |
| `…runners.<name>.githubApp` | `nullOr submodule` | `null` | GitHub App credentials used instead of a token. | Derives short-lived credentials on every start. |
| `…githubApp.id` | `int` | — | The GitHub App's numeric ID. | Identifies the App when requesting an installation token. |
| `…githubApp.login` | `str` | — | Organisation or user the App is installed on. | Scopes the installation lookup and registration. |
| `…githubApp.privateKeyFile` | `path` | — | PEM-encoded App private key. | Signs installation token requests. |
| `…runners.<name>.extraLabels` | `listOf str` | `[ ]` | Additional labels advertised by the runner. | Lets workflows target it with `runs-on`. |
| `…runners.<name>.extraPackages` | `listOf package` | `[ ]` | Packages added to the runner's PATH. | Provides workflow tooling the runner would otherwise lack. |
| `…runners.<name>.ephemeral` | `bool` | `false` | Register a fresh runner per job. | Removes the runner after each job; needs PAT or App credentials. |
| `…runners.<name>.workDir` | `nullOr str` | `null` | Directory used as `$GITHUB_WORKSPACE` and for checkouts. | Moves the cleaned-on-start build directory off tmpfs; must exist and be writable. |

## Toolchains

Nine modules under `toolchain/`, each a single boolean. They share one shape:
packages always apply, and editor wiring applies only for the editors you have
enabled — Neovim gets LSP servers, formatters, and test adapters; VS Code gets
extensions and settings.

| Toolchain | Enable option | Default | Packages |
| --- | --- | --- | --- |
| Android | `cnix-dev.toolchain.android.enable` | `false` | `android-studio`, `jdk21`, `gradle`, `jdt-language-server`, `kotlin-language-server`, `ktlint`, `google-java-format` |
| AWS | `cnix-dev.toolchain.aws.enable` | **`true`** | `awscli2`, `terraform`, `terraform-ls`, `terragrunt`, `aws-vault`, `chamber` |
| C/C++ | `cnix-dev.toolchain.cpp.enable` | `false` | `clang`, `clang-tools`, `cmake`, `ninja`, `gnumake`, `pkg-config`, `gdb`, `lldb`, `ccache` |
| Go | `cnix-dev.toolchain.go.enable` | `false` | `go`, `gopls`, `delve`, `golangci-lint`, `goreleaser`, `go-tools`, `gotools` |
| LaTeX | `cnix-dev.toolchain.latex.enable` | `false` | `zathura`, TeX Live (medium, with `latexindent`), `texlab` |
| Markdown | `cnix-dev.toolchain.markdown.enable` | `false` | `pandoc`, `markdownlint-cli`, `markdown-toc`, `marksman` |
| Nix | `cnix-dev.toolchain.nix.enable` | `false` | `nix-tree`, `nixd`, `nixfmt`, `statix` |
| Node.js | `cnix-dev.toolchain.nodejs.enable` | `false` | `nodejs`, `corepack` (priority-pinned), `typescript`, `typescript-language-server`, `oxlint`, `oxfmt` |
| Unity | `cnix-dev.toolchain.unity.enable` | `false` | `unityhub` (wrapped with an ncurses `LD_LIBRARY_PATH`), `git-lfs`, `vulkan-tools`, `dotnet-sdk`, `omnisharp-roslyn`, `csharpier` |

### Editor wiring per toolchain

| Toolchain | Neovim (LSP · formatter · tests) | VS Code (extension · format on save) |
| --- | --- | --- |
| Android | `jdtls`, `kotlin_language_server` · `google-java-format` (Java), `ktlint` (Kotlin) | Java/Gradle/Java Debug/Java Test/Kotlin · Java only |
| AWS | `terraformls` · `terraform_fmt`, `hclfmt` (also installs `hclfmt`) | Terraform, HCL · Terraform |
| C/C++ | `clangd` (background index, clang-tidy, IWYU) · `clang_format` · CTest | clangd, CMake Tools, LLDB DAP · C/C++/ObjC/CUDA |
| Go | `gopls` (unusedparams, shadow, staticcheck) · `goimports` · Go adapter | Go · Go, import organisation on save |
| LaTeX | `texlab` with Zathura forward search · `latexindent`; enables VimTeX configured for continuous `latexmk` | LaTeX Workshop · LaTeX/TeX/BibTeX |
| Markdown | `marksman` · `markdownlint` | markdownlint · Markdown, fix-all on save |
| Nix | `nixd`, `statix` · `nixfmt` | Nix IDE · Nix |
| Node.js | `ts_ls`, `oxlint` · `oxfmt` for JS/TS/JSON/CSS/HTML/YAML · Jest and Vitest adapters | Oxc · 10 web languages, Oxc fix-all on save |
| Unity | `omnisharp` · `csharpier` (filetype map only) | C#, C# Dev Kit, Unity · C# |

All nine register their enable option identically:

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-dev.toolchain.<name>.enable` | `bool` | see table above | e.g. `Enable Go toolchain.` | Installs the toolchain packages and applies its editor wiring. |

## Packages, overlays, and helpers

| Output | What it is |
| --- | --- |
| `devenv` overlay | Pins `pkgs.devenv` to the flake's `devenv` input. |
| `llm-agents` overlay | Re-exports the shared nixpkgs overlay from `llm-agents`. |
| `lib.cnix-dev.nvim.mkRaw` | Wraps a Lua snippet as `{ __raw = …; }` for nixvim settings. |
| `lib.cnix-dev.nvim.mkKeymap` | Builds a keymap attrset; accepts a string third argument as the description, and defaults to `nowait`, `noremap`, and `silent`. |

## Notes

- **A toolchain is a switch, an editor is a prerequisite.** Nothing from a
  toolchain's editor block applies unless `editor.nvim.enable` (or
  `editor.code.enable`) is also true — the packages still install either way, so
  a CLI-only setup works.
- **Two defaults are on**: `cnix-dev.ai.useRecommendedPackages` and
  `cnix-dev.toolchain.aws.enable`. AWS tooling installs unless you turn it off.
- **`term.useTerms` has a type/default mismatch** in the source (a boolean default
  for a `listOf str`). Pass an explicit list.
- **Toolchain behaviour is documented in-tree** as well: the subtree README
  carries a per-toolchain support matrix.
- **Self-hosted runners are meant for private repositories.** GitHub recommends
  them only there, because a public repository lets fork pull requests run
  untrusted code on the host. Keep the repository private or gate the workflow
  before routing jobs to the runner.
- The `cirius-dev` flake is under active development — the state above matches the
  current working tree.
