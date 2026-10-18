import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const githubUrl = 'https://github.com/cirius-nix/cirius-nix-facade';

const config: Config = {
  title: 'Cirius Nix Facade',
  tagline: 'Small, composable Nix flakes — one per concern',
  favicon: 'img/favicon.svg',

  future: {
    v4: true,
  },

  url: 'https://cirius-nix.github.io',
  baseUrl: '/cirius-nix-facade/',

  organizationName: 'cirius-nix',
  projectName: 'cirius-nix-facade',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: `${githubUrl}/tree/main/apps/website/`,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Cirius Nix Facade',
      logo: {
        alt: 'Cirius Nix Facade logo',
        src: 'img/logo.svg',
        srcDark: 'img/logo-dark.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: githubUrl,
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Introduction',
              to: '/docs/intro',
            },
            {
              label: 'Getting started',
              to: '/docs/getting-started',
            },
            {
              label: 'Layout',
              to: '/docs/layout',
            },
            {
              label: 'Development',
              to: '/docs/development',
            },
          ],
        },
        {
          title: 'Flakes',
          items: [
            {
              label: 'cirius-dev',
              href: `${githubUrl}/tree/main/flakes/cirius-dev`,
            },
            {
              label: 'cirius-lib',
              href: `${githubUrl}/tree/main/flakes/cirius-lib`,
            },
            {
              label: 'cirius-security',
              href: `${githubUrl}/tree/main/flakes/cirius-security`,
            },
            {
              label: 'cirius-visual',
              href: `${githubUrl}/tree/main/flakes/cirius-visual`,
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: githubUrl,
            },
            {
              label: 'Adding a flake or module',
              to: '/docs/adding-a-flake-or-module',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Cirius Nix. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['nix', 'bash', 'yaml', 'json'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
