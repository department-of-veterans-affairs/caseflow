const custom = require('../webpack.config.js');

module.exports = {
  stories: ['../stories/**/*.@(stories|story).@(js|mdx)', '../app/**/*.@(stories|story).@(js|mdx)'],
  addons: [
    {
      name: '@storybook/addon-docs',
      options: {
        configureJSX: true
      }
    },
    '@storybook/addon-controls',
    '@storybook/addon-actions',
    '@storybook/addon-a11y'
  ],
  webpackFinal: (config) => {
    return { ...config, module: { ...config.module, rules: [...config.module.rules, ...custom.module.rules] } };
  }
};
