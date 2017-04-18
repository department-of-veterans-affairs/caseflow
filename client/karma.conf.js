const _ = require('lodash');
const webpackConfig = require('./webpack.config.js');

const karmaTestPattern = 'test/karma/**/*-test.js';

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha'],
    singleRun: true,

    files: [
      { pattern: karmaTestPattern }
    ],

    preprocessors: {
      [karmaTestPattern]: ['webpack', 'sourcemap']
    },

    // Note that karma-webpack will ignore the `entry` value for
    // our webpack config, and will instead run the compiler for
    // each file matched by the test pattern specified above.
    // This means that our other entry points, which we use
    // for shims and polyfills, need to be manually imported
    // in the tests.
    webpack: _.merge({
      externals: {
        cheerio: 'window',
        'react/addons': true,
        'react/lib/ExecutionEnvironment': true,
        'react/lib/ReactContext': true
      }
    }, webpackConfig)
  });
};
