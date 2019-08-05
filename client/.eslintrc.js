module.exports = {
  env: {
    browser: true,
    mocha: true
  },
  extends: [
    '@department-of-veterans-affairs/eslint-config-appeals'
  ],
  rules: {
    'prefer-const': 'off',
    'max-statements': 'off',
    'react/prop-types': [1, { ignore: [],
      customValidators: [] }]
  },
  settings: {
    react: {
      version: '16.2'
    }
  },
  globals: {
    $ReadOnly: true,
    Raven: true
  }
};
