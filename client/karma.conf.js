const _ = require('lodash');
const webpackConfig = require('./webpack.config.js');

const files = [
  'test/karma/test-index.js'
];

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

    files,

    mochaReporter: {
      showDiff: true
    },

    preprocessors: _(files).
      map((file) => [file, ['webpack']]).
      fromPairs().
      value(),

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
