---
title: Development
sidebar_position: 4
description: The devenv shell for working on the facade, and how to work on this website.
---

# Development

## Repository shell

The repository root is a [devenv](https://devenv.sh/) shell providing Nix tooling
and [go-task](https://taskfile.dev/). Enter it with:

```sh
devenv shell
```

## Updating inputs

Each subflake locks its own inputs. To update every one of them at once:

```sh
task update-flakes
```

This walks each `flakes/*/` directory and runs `nix flake update` inside it.

## This website

The site is a [Docusaurus](https://docusaurus.io/) project under
`apps/website`, installed and built with pnpm:

```sh
cd apps/website
pnpm install
pnpm start     # dev server with hot reload
pnpm build     # production build into build/
pnpm typecheck # tsc
```

Pushes to `main` that touch `apps/website` are built and deployed to GitHub Pages
by the `deploy-website` workflow.

### Documentation upkeep

The pages under `docs/flakes/` document each subflake's modules and options by
hand. They are part of the change, not an afterthought: a new option or a changed
default should be reflected there in the same commit.
