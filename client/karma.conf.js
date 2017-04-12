const webpackConfig = require('./webpack.config.js');

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha'],

    files: [
      { pattern: 'test/**/*-test.js' }
    ],

    preprocessors: {
      'test/**/*-test.js': ['webpack', 'sourcemap']
    },

    webpack: webpackConfig
  });
};
