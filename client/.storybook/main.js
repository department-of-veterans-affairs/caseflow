const custom = require('../webpack.config.js');

module.exports = {
  stories: [
    '../stories/**/*.(stories|story).(js|mdx)',
    '../app/**/*.(stories|story).(js|mdx)',
  ],
  addons: [
    '@storybook/addon-knobs',
    '@storybook/addon-actions',
    '@storybook/addon-a11y',
    {
      name: '@storybook/addon-docs',
      options: {
        configureJSX: true,
      },
    },
  ],
  webpackFinal: (config) => {
    const customRules = custom.module.rules.filter((rule) => {
      return !rule.test.toString().includes('woff') && !rule.test.toString().includes('svg');
    });

    return {
      ...config,
      module: {
        ...config.module,
        rules: [...config.module.rules, ...customRules],
      },
    };
  },
};
