const custom = require('../webpack.config.js');

module.exports = {
  stories: ['../stories/**/*.@(stories|story).@(js|mdx)', '../app/**/*.@(stories|story).@(js|mdx)'],

  addons: [{
    name: '@storybook/addon-docs',
    options: {
      configureJSX: true,
    },
  }, '@storybook/addon-controls', '@storybook/addon-actions', '@storybook/addon-a11y', '@storybook/addon-mdx-gfm', '@chromatic-com/storybook'],

  webpackFinal: (config) => {
    const customRules = custom.module.rules.filter((rule) => {
      return !rule.test.toString().includes('woff') && !rule.test.toString().includes('svg');
    });

    return {
      ...config,
      resolve: {
        ...config.resolve,
        alias: {
          ...config.resolve.alias,
          ...custom.resolve.alias
        }
      },
      module: {
        ...config.module,
        rules: [...config.module.rules, ...customRules],
      },
    };
  },

  framework: {
    name: '@storybook/react-webpack5',

    options: {
      fastRefresh: true,
      strictMode: true
    }
  },

  docs: {
    autodocs: true
  },

  typescript: {
    reactDocgen: 'react-docgen-typescript'
  }
};
