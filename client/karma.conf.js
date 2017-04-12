const _ = require('lodash');
const webpackConfig = require('./webpack.config.js');

module.exports = function(config) {
  config.set({
    browsers: ['Chrome'],
    frameworks: ['mocha'],
    singleRun: true,

    files: [
      { pattern: 'test/**/*.js' }
    ],

    preprocessors: {
      'test/**/*.js': ['webpack', 'sourcemap']
    },

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
