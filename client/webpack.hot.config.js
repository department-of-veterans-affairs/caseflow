// This is our webpack dev server, which allows for hot module reloading
//
// Run with Rails server like this:
// rails s
// cd client && npm run hot:dev

const webpack = require('webpack');
const path = require('path');

const config = require('./webpack.config');

const hotRailsPort = process.env.HOT_RAILS_PORT || 3500;

config.entry.push(
  `webpack-dev-server/client?http://localhost:${hotRailsPort}`,
  'webpack/hot/only-dev-server'
);

config.output = {
  filename: 'webpack-bundle.js',
  path: path.join(__dirname, 'public'),
  publicPath: `http://localhost:${hotRailsPort}/`,
};

config.plugins.push(
  new webpack.HotModuleReplacementPlugin(),
  new webpack.NoEmitOnErrorsPlugin(),
  new webpack.NamedModulesPlugin()
);

module.exports = config;
