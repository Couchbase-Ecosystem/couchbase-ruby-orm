import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: JSX.Element;
};
const FeatureList: FeatureItem[] = [
  {
    title: 'Flexible Data Model',
    Svg: require('@site/static/img/logo.svg').default,
    description: (
      <>
        Couchbase offers a flexible data model, allowing you to easily adapt your
        application to changing requirements without downtime.
      </>
    ),
  },
  {
    title: 'Scalability and Performance',
    Svg: require('@site/static/img/fast.svg').default,
    description: (
      <>
        Couchbase provides scalable and high-performance data operations, ensuring
        your application can handle large volumes of data and user requests.
      </>
    ),
  },
  {
    title: 'Familiar Query Language',
    Svg: require('@site/static/img/familiar.svg').default,
    description: (
      <>
        Couchbase supports a familiar SQL-like querying language, making it
        easy for users to query and analyze data with their existing skills.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
