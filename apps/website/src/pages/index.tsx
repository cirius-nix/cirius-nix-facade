import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';

import styles from './index.module.css';

const githubUrl = 'https://github.com/cirius-nix/cirius-nix-facade';

const usageSnippet = `{
  inputs.cirius-dev = {
    url = "github:cirius-nix/cirius-nix-facade/main?dir=flakes/cirius-dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}`;

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link className="button button--secondary button--lg" to="/docs/intro">
            Read the docs
          </Link>
          <Link
            className={clsx(
              'button button--outline button--lg',
              styles.outlineButton,
            )}
            href={githubUrl}>
            View on GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

function UsageSection() {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className="row">
          <div className="col col--5">
            <Heading as="h2">Capture the settings that matter</Heading>
            <p>
              Every subflake is referenced directly by directory with the{' '}
              <code>?dir=</code> query parameter, so a host pulls in only the
              concerns it needs — and locks each one on its own schedule. What it
              covers is the core configuration worth keeping; everything else
              stays plain NixOS and home-manager.
            </p>
            <Link to="/docs/flakes">Browse the flakes →</Link>
          </div>
          <div className="col col--7">
            <CodeBlock language="nix" title="flake.nix">
              {usageSnippet}
            </CodeBlock>
          </div>
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout description={siteConfig.tagline}>
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <UsageSection />
      </main>
    </Layout>
  );
}
