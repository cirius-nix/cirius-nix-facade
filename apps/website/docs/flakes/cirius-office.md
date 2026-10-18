---
title: cirius-office
sidebar_position: 9
description: Document, PDF, and reference tooling in tiers, plus an Obsidian setup.
---

# cirius-office

Document work in three tiers. `basic` is the everyday set, `technical` adds the
document-production toolchain, and `research` adds reference management and OCR.
The tier is a single enum, so a machine gets exactly the level of tooling it
needs instead of the union of everything.

| | |
| --- | --- |
| Namespace | `cnix-office` |
| Module classes | `home` |
| External inputs | — |
| Options | 2 |

## Usage

```nix
{ inputs, ... }:
{
  imports = [ inputs.cirius-office.homeModules.default ];

  cnix-office.enable = true;
  cnix-office.variant = "technical";
}
```

## Modules

| Module | Class | Enabled by | Gates |
| --- | --- | --- | --- |
| `default` | home | `cnix-office.enable` | Office packages and Obsidian |

### `home/default` — tiered office tooling

**Enable:** `cnix-office.enable`

Every level includes the base set: OnlyOffice desktop editors, PDF Arranger and
`poppler-utils` for PDF work, Calibre, Teams, Thunderbird, and Obsidian with its
CLI.

| Variant | Adds |
| --- | --- |
| `basic` | Base set only |
| `technical` | `pandoc`, `texliveMedium`, `mermaid-cli`, `typst`, `drawio`, `graphviz` |
| `research` | `jabref`, `ocrmypdf`, `quarto` |

The tiers nest: a level is applied when its rank is at or below the selected
variant, so `research` also installs everything `technical` and `basic` include.

| Option | Type | Default | Description | Effect |
| --- | --- | --- | --- | --- |
| `cnix-office.enable` | `bool` | `false` | Enable office tools. | Installs the selected variant's packages and enables Obsidian. |
| `cnix-office.variant` | `enum [ "basic" "technical" "research" ]` | `"basic"` | Choose the variant of office tools to install. | Selects which package tiers apply. |

## Notes

- This flake's `modules/home/default` is both the aggregate module and the module
  that declares the options — there are no sibling modules to import.
- `zotero` is deliberately absent from the `research` tier: it is noted in the
  source as failing to build.
