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
    title: 'One flake per concern',
    to: '/docs/intro',
    linkLabel: 'Why a facade',
    description: (
      <>
        Eleven subflakes under <code>flakes/</code> cover dev tooling, security,
        desktop, networking, gaming, art, and more.
      </>
    ),
  },
  {
    title: 'Convention over configuration',
    to: '/docs/layout',
    linkLabel: 'Directory layout',
    description: (
      <>
        snowfall-lib <code>mkFlake</code> discovers modules, packages, and
        overlays from a predictable layout, so extending the facade is usually a
        matter of dropping a file in the right place.
      </>
    ),
  },
  {
    title: 'Locked per concern',
    to: '/docs/development',
    linkLabel: 'Development',
    description: (
      <>
        Every subflake owns its <code>flake.lock</code>, so updating your dev
        toolchain never moves your desktop stack.
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
