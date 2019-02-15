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
    'max-statements': 'off'
  },
  globals: {
    $ReadOnly: true,
    Raven: true
  }
};
