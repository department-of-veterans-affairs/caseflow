module.exports = {
  env: {
    browser: true,
    mocha: true
  },
  extends: ['@department-of-veterans-affairs/eslint-config-appeals'],
  rules: {
    'prefer-const': 'off',
    'max-statements': 'off',
    'react/prop-types': [1, { ignore: [],
      customValidators: [] }]
  },
  plugins: [
    'nullishCoalescingOperator'
  ],
  settings: {
    react: {
      version: '16.12'
    },
    'import/resolver': {
      node: {
        extensions: ['.js', '.jsx', '.json']
      }
    }
  },
  globals: {
    $ReadOnly: true,
    Raven: true
  }
};
