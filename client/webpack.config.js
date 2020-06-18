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
      ie: 'component-ie'
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
        test: /\.module\.s(a|c)ss$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              modules: true,
              sourceMap: true
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
        test: /\.scss?$/,
        exclude: /\.module.(s(a|c)ss)$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              sourceMap: true
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
        test: /\.css?$/,
        use: [
          {
            loader: 'style-loader'
          },
          {
            loader: 'css-loader',
            options: {
              sourceMap: true,
              url: false
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
