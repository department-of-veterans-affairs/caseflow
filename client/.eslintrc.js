module.exports = {
  env: {
    browser: true,
    mocha: true
  },
  extends: ['@department-of-veterans-affairs/eslint-config-appeals', 'plugin:jest/recommended'],
  parserOptions: {
    ecmaFeatures: {
      jsx: true
    },
    ecmaVersion: 10,
    sourceType: 'module'
  },
  rules: {
    'prefer-const': 'off',
    'max-statements': 'off',
    'react/prop-types': [
      1,
      {
        ignore: [],
        customValidators: []
      }
    ],
    // Adding next two rules to avoid bug in babel-eslint:
    // https://github.com/babel/babel-eslint/issues/799
    indent: ['warn', 2, { ignoredNodes: ['TemplateLiteral'] }],
    'template-curly-spacing': 'off'
  },
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
