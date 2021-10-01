// Forked from:
// module.exports = require('@department-of-veterans-affairs/caseflow-frontend-toolkit/config/karma.conf');
/* eslint-disable no-process-env */

const _ = require('lodash');
const process = require('process');
const webpackConfig = require('./webpack.config');

const files = ['test/karma/test-index.js'];

const filesPreprocessorObject = _(files).
  map((file) => [file, ['webpack']]).
  fromPairs().
  value();

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['snapshot'],
    singleRun: true,

    browserConsoleLogOptions: {
      terminal: true,
      level: ''
    },

    files: ['**/__snapshots__/**/*.md', ...files],

    preprocessors: _.merge(
      {
        '**/__snapshots__/**/*.md': ['snapshot']
      },
      filesPreprocessorObject
    ),

    snapshot: {
      update: Boolean(process.env.UPDATE),
      prune: Boolean(process.env.PRUNE)
    },

    webpack: _.merge(
      {
        watch: true,
        externals: {
          cheerio: 'window',
          'react/addons': true,
          'react/lib/ExecutionEnvironment': true,
          'react/lib/ReactContext': true
        }
      },
      webpackConfig
    )
  });
};
