/* eslint-disable no-process-env */
const _ = require('lodash');
const webpackConfig = require('./webpack.config.js');

const karmaTestPattern = 'test/karma/**/*-test.js';

module.exports = function(config) {
  // CHROME_ARGS is expected to be a space separated list of arguments
  const chromeArgs = process.env.CHROME_ARGS ? process.env.CHROME_ARGS.split(' ') : [];

  config.set({
    browsers: ['Chrome_with_options'],
    frameworks: ['mocha'],
    reporters: ['mocha'],
    singleRun: true,

    browserConsoleLogOptions: {
      terminal: true,
      level: ''
    },

    customLaunchers: {
      Chrome_with_options: {
        base: 'Chrome',
        // The CHROME_ARGS environment is set in test envrionments
        // to allow headless tests to run
        flags: chromeArgs
      }
    },

    files: [
      'test/karma/setup.js',
      { pattern: karmaTestPattern }
    ],

    mochaReporter: {
      showDiff: true
    },

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
