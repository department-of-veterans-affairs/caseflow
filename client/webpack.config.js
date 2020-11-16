const webpack = require('webpack');
const path = require('path');
const _ = require('lodash');

const devBuild = process.env.NODE_ENV !== 'production'; // eslint-disable-line no-process-env

const config = {
  mode: devBuild ? 'development' : 'production',
  entry: ['./app/index'],
  output: {
    filename: 'webpack-bundle.js',
    sourceMapFilename: 'sourcemap-[file].map',
    path: path.join(__dirname, '../app/assets/javascripts')
  },
  plugins: _.compact([
    new webpack.EnvironmentPlugin({ NODE_ENV: 'development' })
  ]),
  resolve: {
    extensions: ['.js', '.jsx', '.json'],
    alias: {
      // This does not actually appear to be necessary, but it does silence
      // a warning from superagent-no-cache.
      ie: 'component-ie',
      app: path.resolve('app'),
      constants: path.resolve('constants'),
      layouts: path.resolve('app/2.0/layouts'),
      routes: path.resolve('app/2.0/routes'),
      store: path.resolve('app/2.0/store'),
      screens: path.resolve('app/2.0/screens'),
      components: path.resolve('app/2.0/components'),
      test: path.resolve('test'),
    }
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: new RegExp(
          'node_modules/(?!@department-of-veterans-affairs/caseflow-frontend-toolkit)'
        ),
        use: [
          {
            loader: 'babel-loader'
          }
        ]
      },
      {
        test: /\.(ttf|eot|woff|woff2)$/,
        use: {
          loader:
            'url-loader?limit=1024&name=fonts/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/'
        }
      },
      {
        test: /\.((c|sa|sc)ss)$/i,
        use: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              importLoaders: 1,
              modules: { auto: true },
              sourceMap: true,
              localsConvention: 'camelCase'
            }
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: true
            }
          }
        ]
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [
          'url-loader?limit=1024&name=images/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/'
        ]
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
