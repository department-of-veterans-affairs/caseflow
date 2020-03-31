module.exports = {
  stories: [
    '../stories/**/*.(stories|story).(js|mdx)',
    '../app/**/*.(stories|story).(js|mdx)'
  ],
  addons: [
    '@storybook/addon-knobs',
    '@storybook/addon-actions',
    '@storybook/addon-a11y',
    {
      name: '@storybook/addon-docs',
      options: {
        configureJSX: true
      }
    }
  ]
};
