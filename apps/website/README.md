# Website

Landing page and documentation for the Cirius Nix Facade, built with
[Docusaurus](https://docusaurus.io/) and deployed to GitHub Pages.

Published at <https://cirius-nix.github.io/cirius-nix-facade/>.

## Development

Requires Node.js and pnpm.

```sh
pnpm install
pnpm start
```

The dev server opens a browser window and hot-reloads most changes.

## Build

```sh
pnpm build     # static output in build/
pnpm serve     # serve the built output locally
pnpm typecheck # tsc
```

## Deployment

Deployment is automatic. `.github/workflows/deploy-website.yml` builds the site
and publishes it to GitHub Pages on every push to `main` that touches
`apps/website`, and can also be triggered manually with `workflow_dispatch`.

This requires the repository to be configured with
**Settings → Pages → Build and deployment → Source = GitHub Actions**.

## Configuration notes

- The site is served from the `/cirius-nix-facade/` sub-path; `url` and `baseUrl`
  in `docusaurus.config.ts` must match the GitHub Pages location.
- Docs live in `docs/` and are listed explicitly in `sidebars.ts`.
- Pages, layout, and styling live in `src/pages`, `src/components`, and
  `src/css/custom.css`.
