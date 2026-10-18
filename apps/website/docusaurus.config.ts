import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const githubUrl = 'https://github.com/cirius-nix/cirius-nix-facade';

const config: Config = {
  title: 'Cirius Nix Facade',
  tagline:
    'Simple by default, powerful when needed — the core settings that keep Linux running well',
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
              label: 'Design',
              to: '/docs/design',
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
              label: 'All flakes',
              to: '/docs/flakes',
            },
            {
              label: 'cirius-utils',
              to: '/docs/flakes/cirius-utils',
            },
            {
              label: 'cirius-dev',
              to: '/docs/flakes/cirius-dev',
            },
            {
              label: 'cirius-security',
              to: '/docs/flakes/cirius-security',
            },
            {
              label: 'cirius-visual',
              to: '/docs/flakes/cirius-visual',
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
              label: 'Extending',
              to: '/docs/extending',
            },
            {
              label: 'cirius-lib',
              to: '/docs/flakes/cirius-lib',
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
