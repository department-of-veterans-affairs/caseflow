const webpack = require('webpack');
const path = require('path');
const _ = require('lodash');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

const env = process.env.NODE_ENV; // eslint-disable-line no-process-env
const devBuild = env !== 'production';
const generateSourceMap = env !== 'test';

const config = {
  entry: ['es5-shim/es5-shim', 'es5-shim/es5-sham', 'babel-polyfill', './app/index'],
  output: {
    filename: 'webpack-bundle.js',
    sourceMapFilename: 'sourcemap-[file].map',
    path: path.join(__dirname, '../app/assets/javascripts')
  },
  plugins: _.compact([
    devBuild ? null : new webpack.optimize.ModuleConcatenationPlugin(),
    new webpack.EnvironmentPlugin({ NODE_ENV: 'development' }),
    devBuild ? null : new UglifyJsPlugin({
      sourceMap: generateSourceMap,
      parallel: true
    })
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
      },
      {
        test: /\.(ttf|eot|woff|woff2)$/,
        loader: 'url-loader?limit=1024&name=fonts/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/'
      },
      {
        test: /\.module\.s(a|c)ss$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              modules: true,
              sourceMap: generateSourceMap
            }
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: generateSourceMap
            }
          }
        ]
      },
      {
        test: /\.scss?$/,
        exclude: /\.module.(s(a|c)ss)$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              sourceMap: generateSourceMap
            }
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: generateSourceMap
            }
          }
        ]
      },
      {
        test: /\.css?$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              sourceMap: generateSourceMap,
              url: false
            }
          }
        ]
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: ['url-loader?limit=1024&name=images/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/']
      }
    ]
  }
};

if (env === 'production') {
  console.log('Webpack production build for Rails'); // eslint-disable-line no-console
  console.log('Generating source maps...'); // eslint-disable-line no-console
  config.devtool = 'source-map';
} else if (env === 'test') {
  console.log('Webpack test build for Rails'); // eslint-disable-line no-console
} else {
  console.log('Webpack dev build for Rails'); // eslint-disable-line no-console
  config.devtool = 'eval-source-map';
}

module.exports = config;
