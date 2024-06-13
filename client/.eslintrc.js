module.exports = {
  env: {
    browser: true,
    mocha: true,
  },
  extends: ['@department-of-veterans-affairs/eslint-config-appeals', 'plugin:jest/recommended'],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 10,
    sourceType: 'module',
  },
  plugins: ['babel'],
  rules: {
    'comma-dangle': ['warn', 'only-multiline'],
    'prefer-const': 'off',
    'max-statements': 'off',
    'react/prop-types': [
      1,
      {
        ignore: [],
        customValidators: [],
      },
    ],
    // Adding next two rules to avoid bug in babel-eslint:
    // https://github.com/babel/babel-eslint/issues/799
    indent: ['warn', 2, { ignoredNodes: ['TemplateLiteral'] }],
    'template-curly-spacing': 'off',

    // Replace certain rules that fail to properly handle new language syntaxes
    // See https://github.com/babel/eslint-plugin-babel#rules for list
    'no-unused-expressions': 'off',
    'babel/no-unused-expressions': 'error',
  },
  settings: {
    react: {
      version: '16.12',
    },
    'import/resolver': {
      webpack: {
        config: './webpack.config.js',
      },
      node: {
        extensions: ['.js', '.jsx', '.json'],
      },
    },
  },
  globals: {
    $ReadOnly: true,
    Raven: true,
  },
};
