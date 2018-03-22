// Forked from:
// module.exports = require('@department-of-veterans-affairs/caseflow-frontend-toolkit/config/karma.conf');
/* eslint-disable no-process-env */

const _ = require('lodash');
const process = require('process');
const webpackConfig = require('@department-of-veterans-affairs/caseflow-frontend-toolkit/config/getWebpackConfig')(__dirname);

const files = [
  'test/karma/test-index.js'
];

const filesPreprocessorObject = _(files).
  map((file) => [file, ['webpack']]).
  fromPairs().
  value();

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha', 'snapshot', 'mocha-snapshot'],
    reporters: ['mocha'],
    singleRun: true,

    browserConsoleLogOptions: {
      terminal: true,
      level: ''
    },

    files: [
      '**/__snapshots__/**/*.md',
      ...files
    ],

    mochaReporter: {
      showDiff: true
    },

    junitReporter: {
      outputDir: process.env.KARMA_JUNIT_OUTPUT_DIR,
      outputFile: process.env.KARMA_JUNIT_OUTPUT_FILE,
      useBrowserName: false
    },

    preprocessors: _.merge({
      '**/__snapshots__/**/*.md': ['snapshot']
    }, filesPreprocessorObject),

    snapshot: {
      /* eslint-disable no-process-env */
      update: Boolean(process.env.UPDATE),
      prune: Boolean(process.env.PRUNE)
      /* eslint-enable no-process-env */
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
