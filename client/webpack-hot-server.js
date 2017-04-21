// This is what creates the hot assets so that you can edit assets, JavaScript (and eventually SCSS),
// referenced in your webpack config, and the page updated without you needing to reload
// the page.
//
// To use this while deving run:
// $ npm run dev:hot
// $ REACT_ON_RAILS_ENV=hot bundle exec rails s

const webpack = require('webpack');
const WebpackDevServer = require('webpack-dev-server');
const webpackConfig = require('./webpack.hot.config');

const hotRailsPort = process.env.HOT_RAILS_PORT || 3500;

const compiler = webpack(webpackConfig);
const baseUrl = `http://localhost:${hotRailsPort}`;

const devServer = new WebpackDevServer(compiler, {
  publicPath: webpackConfig.output.publicPath,
  hot: true,
  inline: true,
  historyApiFallback: false,
  quiet: false,
  noInfo: false,
  lazy: false,
  proxy: {
    '*': baseUrl
  },
  stats: {
    colors: true,
    hash: false,
    version: false,
    chunks: false,
    children: false,
  },
});

devServer.listen(hotRailsPort, 'localhost', err => {
  if (err) console.error(err);
  console.log(
    `=> 🔥  Webpack development server is running on port ${hotRailsPort}`
  );
});
