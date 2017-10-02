const _ = require('lodash');
const webpackConfig = require('./webpack.config.js');

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha'],
    reporters: ['mocha'],
    singleRun: true,

    browserConsoleLogOptions: {
      terminal: true,
      level: ''
    },

    files: [
      'test/karma/setup.js',
      'test/karma/test-index.js'
    ],

    mochaReporter: {
      showDiff: true
    },

    preprocessors: {
      'test/karma/test-index.js': ['webpack']
    },

    webpack: _.merge({
      watch: true,
      externals: {
        cheerio: 'window',
        'react/addons': true,
        'react/lib/ExecutionEnvironment': true,
        'react/lib/ReactContext': true
      }
    }, webpackConfig)
  });
};
