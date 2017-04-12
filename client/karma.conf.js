const webpackConfig = require('./webpack.config.js');

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha'],
    singleRun: true,

    files: [
      { pattern: 'test/**/specialIssues-test.js' }
    ],

    preprocessors: {
      'test/**/specialIssues-test.js': ['webpack', 'sourcemap']
    },

    webpack: webpackConfig
  });
};
