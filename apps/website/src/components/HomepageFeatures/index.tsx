import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  to: string;
  linkLabel: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Less setup per machine',
    to: '/docs/getting-started',
    linkLabel: 'Getting started',
    description: (
      <>
        A new host enables a handful of <code>cnix-*</code> options instead of
        re-deriving the same shell, git, editor, and security setup from scratch.
      </>
    ),
  },
  {
    title: 'Less infra-as-code to own',
    to: '/docs/design',
    linkLabel: 'Design',
    description: (
      <>
        Eleven subflakes, around 160 namespaced option paths, and no root{' '}
        <code>flake.nix</code> — small enough to read in one sitting and keep
        working.
      </>
    ),
  },
  {
    title: 'Simple by default, powerful when needed',
    to: '/docs/flakes',
    linkLabel: 'Flake reference',
    description: (
      <>
        Every module is off until you enable it, and every option has a default.
        Underneath, they set ordinary NixOS options you can override, extend, or
        bypass.
      </>
    ),
  },
];

function Feature({title, to, linkLabel, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.card}>
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
        <Link to={to} className={styles.cardLink}>
          {linkLabel} →
        </Link>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((feature) => (
            <Feature key={feature.title} {...feature} />
          ))}
        </div>
      </div>
    </section>
  );
}
