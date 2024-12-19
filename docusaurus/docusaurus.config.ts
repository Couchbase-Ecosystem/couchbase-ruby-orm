import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Ruby Couchbase ORM',
  tagline: 'Quickstart guide for Ruby Couchbase ORM',
  favicon: 'img/logo.svg',

  // Set the production url of your site here
  url: 'https://ruby-cb-orm.com',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'couchbase-examples', // Usually your GitHub org/user name.
  projectName: 'ruby-couchbase-orm-quickstart', // Usually your repo name.
  trailingSlash: false,

  onBrokenLinks: 'warn', // TODO: 'throw' when all links are fixed
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.ts'),
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl: `https://github.com/couchbase-examples/ruby-couchbase-orm-quickstart/tree/docs/docusaurus/docusaurus/docs`,
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    navbar: {
      title: 'Ruby Couchbase ORM',
      logo: {
        alt: 'Ruby Couchbase ORM Tutorial Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Tutorial',
        },
        {
          href: 'https://github.com/Couchbase-Ecosystem/ruby-orm',
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
              label: 'Tutorial',
              to: '/docs/intro',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Stack Overflow',
              href: 'https://stackoverflow.com/questions/tagged/couchbase',
            },
            {
              label: 'Discord',
              href: 'https://bit.ly/3JGCeUg',
            },
            {
              label: 'Twitter',
              href: 'https://x.com/couchbase',
            },
          ],
        },
        {
          title: 'More',
          items: [
            
            {
              label: 'GitHub',
              href: 'https://github.com/Couchbase-Ecosystem/couchbase-ruby-orm',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Couchbase, Inc. Licensed under the Apache License, Version 2.0.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;