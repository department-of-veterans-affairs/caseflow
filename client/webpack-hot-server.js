// File likely no longer needed -- marked for removal in future

// This is what creates the hot assets so that you can edit assets,
// JavaScript (and eventually SCSS), referenced in your webpack config,
// and the page updated without you needing to reload the page.
// To use this while deving see the README

const webpack = require('webpack');
const WebpackDevServer = require('webpack-dev-server');
const webpackConfig = require('./webpack.hot.config');

/* eslint-disable no-process-env */
const hotRailsPort = process.env.HOT_RAILS_PORT || 3500;
/* eslint-enable no-process-env */

const compiler = webpack({ ...webpackConfig });
const baseUrl = `http://localhost:${hotRailsPort}`;

const devServer = new WebpackDevServer(compiler, {
  publicPath: webpackConfig.output.publicPath,
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': 'true',
  },
  hot: true,
  inline: false,
  quiet: false,
  noInfo: false,
  proxy: {
    '*': baseUrl,
  },
  stats: {
    colors: true,
  },
});

devServer.listen(hotRailsPort, '0.0.0.0', (err) => {
  /* eslint-disable no-console */
  if (err) {
    console.error(err);
  }
  console.log(
    `=> 🔥  Webpack development server is running on port ${hotRailsPort}`
  );
  /* eslint-enable no-console */
});
