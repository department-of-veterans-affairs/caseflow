const webpack = require('webpack');
const path = require('path');
const _ = require('lodash');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const bourbon = require('bourbon').includePaths;
const neat = require('bourbon-neat').includePaths;
const ExtractTextPlugin = require('extract-text-webpack-plugin');

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
    path: path.join(__dirname, '../app/assets/webpack')
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
      ie: 'component-ie',
      // Makes it easier to reference our assets in jsx files
      assets: path.resolve('./app/assets')
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
      },
      {
        test: /\.scss$/,
        loader: ExtractTextPlugin.extract('style-loader', `css!resolve-url!sass?includePaths[]=${bourbon}&includePaths[]=${neat}&includePaths[]=` + '~/uswds/src/stylesheets' + '&sourceMap')
      },
      { test: /\.(jpe?g|png|gif|svg)$/i,
        loader: 'url?limit=10000!img?progressive=true&-minimize'
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader?limit=10000&minetype=application/font-woff'
      },
      {
        test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader'
      }

    ]
  },
  plugins: [
    new ExtractTextPlugin('webpack-bundle.css'),
  ]
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

