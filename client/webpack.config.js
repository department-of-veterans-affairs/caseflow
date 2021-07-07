const webpack = require('webpack');
const path = require('path');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');

const devBuild = process.env.NODE_ENV !== 'production'; // eslint-disable-line no-process-env
const testBuild = process.env.NODE_ENV === 'test'; // eslint-disable-line no-process-env

const config = {
  mode: devBuild ? 'development' : 'production',
  entry: ['./app/index'],
  output: {
    filename: 'webpack-bundle.js',
    sourceMapFilename: 'sourcemap-[file].map',
    path: path.join(__dirname, '../app/assets/javascripts'),
    publicPath: devBuild && !testBuild ? 'http://localhost:3500/' : 'assets/'
  },
  plugins: [
    new webpack.EnvironmentPlugin({ NODE_ENV: 'development' }),
    devBuild && new webpack.HotModuleReplacementPlugin(),
    devBuild && !testBuild && new ReactRefreshWebpackPlugin(),
  ].filter(Boolean),
  devServer: {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true',
    },
    hotOnly: true,
    contentBase: './',
    port: 3500,
    proxy: {
      '*': 'http://localhost:3500',
    },
    watchOptions: {
      poll: true,
      ignored: '/node_modules/',
    },
  },
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
      utils: path.resolve('app/2.0/utils'),
      styles: path.resolve('app/2.0/styles'),
      test: path.resolve('test'),
    },
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
            loader: 'babel-loader',
            options: {
              plugins: [
                devBuild &&
                  !testBuild &&
                  require.resolve('react-refresh/babel'),
              ].filter(Boolean),
            },
          },
        ],
      },
      {
        test: /\.(ttf|eot|woff|woff2)$/,
        use: {
          loader:
            'url-loader?limit=1024&name=fonts/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/',
        },
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
              localsConvention: 'camelCase',
            },
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: true,
            },
          },
        ],
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [
          'url-loader?limit=1024&name=images/[name]-[hash].[ext]&outputPath=../../../public/&publicPath=/',
        ],
      },
    ],
  },
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
