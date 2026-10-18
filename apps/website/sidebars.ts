import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    'getting-started',
    'design',
    'development',
    'extending',
    {
      type: 'category',
      label: 'Flakes',
      link: {
        type: 'doc',
        id: 'flakes/index',
      },
      items: [
        'flakes/cirius-utils',
        'flakes/cirius-security',
        'flakes/cirius-dev',
        'flakes/cirius-visual',
        'flakes/cirius-networking',
        'flakes/cirius-gaming',
        'flakes/cirius-virt',
        'flakes/cirius-art',
        'flakes/cirius-office',
        'flakes/cirius-vn',
        'flakes/cirius-lib',
      ],
    },
  ],
};

export default sidebars;
