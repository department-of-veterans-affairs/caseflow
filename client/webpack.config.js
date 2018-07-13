const webpack = require('webpack');
const path = require('path');
const _ = require('lodash');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

const devBuild = process.env.NODE_ENV !== 'production'; // eslint-disable-line no-process-env

const config = {
  entry: [
    'es5-shim/es5-shim',
    'es5-shim/es5-sham',
    'babel-polyfill',
    './app/index'
  ],
  output: {
    filename: 'webpack-bundle.js',
    sourceMapFilename: 'sourcemap-[file].map',
    path: path.join(__dirname, '../app/assets/javascripts')
  },
  plugins: _.compact([
    devBuild ? null : new webpack.optimize.ModuleConcatenationPlugin(),
    new webpack.EnvironmentPlugin({ NODE_ENV: 'development' }),
    devBuild ? null : new UglifyJsPlugin({ sourceMap: true })
  ]),
  resolve: {
    extensions: ['.js', '.jsx'],
    alias: {
      // This does not actually appear to be necessary, but it does silence
      // a warning from superagent-no-cache.
      ie: 'component-ie'
    }
  },
  module: {
    loaders: [
      {
        test: require.resolve('react'),
        loader: 'imports-loader?shim=es5-shim/es5-shim&sham=es5-shim/es5-sham'
      },
      {
        test: /\.jsx?$/,
        loader: 'babel-loader',
        exclude: new RegExp('node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)')
      }
    ]
  }
};

if (devBuild) {
  console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
  config.devtool = 'eval-source-map';
} else {
  console.log('Webpack production build for Rails'); // eslint-disable-line no-console
  console.log('Generating source maps...'); // eslint-disable-line no-console
  config.devtool = 'source-map';
}

module.exports = config;
